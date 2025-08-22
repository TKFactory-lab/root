import os
import json
from typing import List, Optional

from dotenv import load_dotenv
from pydantic import BaseModel, Field
from redminelib import Redmine
# Some environments/package versions expose exceptions differently. Try to import
# ResourceNotFound but fall back to a generic Exception when unavailable to
# avoid ImportError during container startup.
try:
    from redminelib.exceptions import ResourceNotFound
except Exception:
    ResourceNotFound = Exception

# Try to import crewai; provide minimal fallbacks if unavailable
try:
    from crewai import Agent, Task, Crew, Process
    from crewai.tools import tool
except Exception:
    def tool(name=None):
        def _decorator(fn):
            try:
                fn.__crewai_tool_name__ = name
            except Exception:
                pass
            return fn

        return _decorator

    class Agent:
        def __init__(self, **kwargs):
            self.__dict__.update(kwargs)

    class Task:
        def __init__(self, **kwargs):
            self.__dict__.update(kwargs)

    class Process:
        sequential = "sequential"

    class Crew:
        def __init__(self, agents=None, tasks=None, process=None, verbose=0):
            self.agents = agents or []
            self.tasks = tasks or []
            self.process = process
            self.verbose = verbose

        def kickoff(self):
            return {"agents": [getattr(a, "role", "unknown") for a in self.agents], "tasks": len(self.tasks)}


# Load environment
load_dotenv()
REDMINE_URL = os.getenv("REDMINE_URL", "http://redmine:3000")
REDMINE_API_KEY = os.getenv("REDMINE_API_KEY") or os.getenv("NOBUNAGA_API_KEY")


class UserStory(BaseModel):
    id: int = Field(..., description="ユーザー・ストーリーの一意なID。")
    priority: str = Field(..., description="ユーザー・ストーリーの優先度（例：高、中、低）。")
    user_story: str = Field(..., description="ユーザーの視点から書かれた機能の説明。")
    acceptance_criteria: str = Field(..., description="機能が完成したと見なされるための条件。")


class ProductBacklog(BaseModel):
    project_name: str = Field(..., description="プロジェクト名。")
    backlog: List[UserStory] = Field(..., description="ユーザー・ストーリーのリスト。")


@tool("Save Product Backlog")
def save_product_backlog_tool(product_backlog: ProductBacklog):
    try:
        os.makedirs("projects", exist_ok=True)
        file_path = f"projects/{product_backlog.project_name}_backlog.json"
        with open(file_path, "w", encoding="utf-8") as f:
            json.dump(product_backlog.model_dump(), f, indent=2, ensure_ascii=False)
        return f"プロダクトバックログが {file_path} に正常に保存されました。"
    except Exception as e:
        return f"ファイル保存中にエラーが発生しました: {e}"


@tool("Redmine Ticket Manager")
def redmine_tool(action: str, project_id: str, subject: str, description: str, assigned_to_id: Optional[int] = None):
    try:
        client = Redmine(REDMINE_URL, key=REDMINE_API_KEY)
        if action == "create_issue":
            issue = client.issue.create(
                project_id=project_id,
                subject=subject,
                description=description,
                assigned_to_id=assigned_to_id,
            )
            return f"Redmineに新しいチケットが正常に作成されました: チケットID {issue.id}"
        return f"指定されたアクション '{action}' はサポートされていません。"
    except Exception as e:
        return f"Redmineツール実行中にエラーが発生しました: {e}"


@tool("Redmine Project Manager")
def redmine_project_tool(action: str, project_name: str, project_identifier: str, description: str):
    try:
        client = Redmine(REDMINE_URL, key=REDMINE_API_KEY)
        if action == "create_project":
            try:
                client.project.get(project_identifier)
                return f"Redmineプロジェクト '{project_name}' は既に存在します。"
            except ResourceNotFound:
                project = client.project.create(
                    name=project_name,
                    identifier=project_identifier,
                    description=description,
                )
                return f"Redmineに新しいプロジェクト '{project.name}' が正常に作成されました: プロジェクトID {project.id}"
        return f"指定されたアクション '{action}' はサポートされていません。"
    except Exception as e:
        return f"Redmineプロジェクトツール実行中にエラーが発生しました: {e}"


@tool("Redmine User Finder")
def redmine_user_finder_tool(username: str):
    try:
        client = Redmine(REDMINE_URL, key=REDMINE_API_KEY)
        users = client.user.all(name=username)
        if users:
            return f"ユーザー '{username}' のIDは {users[0].id} です。"
        return f"ユーザー '{username}' は見つかりませんでした。"
    except Exception as e:
        return f"Redmineユーザー検索中にエラーが発生しました: {e}"


nobunaga_oda = Agent(
    role="プロダクトマネージャー",
    goal="プロダクトビジョンの策定とバックログ管理",
    backstory="Nobunaga Oda - Product Manager",
    verbose=True,
    allow_delegation=False,
    tools=[save_product_backlog_tool, redmine_tool, redmine_project_tool, redmine_user_finder_tool],
)

hide_toyotomi = Agent(
    role="ソフトウェアエンジニア",
    goal="バックログをコードに変換",
    backstory="Hide Toyotomi - Engineer",
    verbose=True,
    allow_delegation=False,
    tools=[redmine_tool],
)

ieyasu_tokugawa = Agent(
    role="QAエンジニア",
    goal="品質保証とテスト",
    backstory="Ieyasu Tokugawa - QA",
    verbose=True,
    allow_delegation=False,
    tools=[redmine_tool],
)

task_create_project = Task(
    description="Create a Redmine project 'SimpleWebApp'",
    expected_output="Project created in Redmine",
    agent=nobunaga_oda,
)

task_initial_request = Task(
    description="Create initial Redmine issue assigned to ktakada",
    expected_output="Issue created",
    agent=nobunaga_oda,
)

task_product_backlog = Task(
    description="Generate product backlog for SimpleWebApp and create issues",
    expected_output="Backlog saved and issues created",
    agent=nobunaga_oda,
)

crew = Crew(
    agents=[nobunaga_oda, hide_toyotomi, ieyasu_tokugawa],
    tasks=[task_create_project, task_initial_request, task_product_backlog],
    process=Process.sequential,
    verbose=2,
)


if __name__ == "__main__":
    print("=== プロジェクトチームの活動開始 ===")
    result = crew.kickoff()
    print("=== プロジェクトチームの活動終了 =====")
    print("\n\n=== チームの成果 ===\n")
    print(result)
 
