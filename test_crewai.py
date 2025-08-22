import os
import logging
from crewai import Agent, Task, Crew

logging.basicConfig(
    filename="log/test_crewai.log",
    filemode="w",
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

logger = logging.getLogger(__name__)

os.environ['CREWAI_SKIP_TRACE_CONFIRM'] = 'true'

def main():
    try:
        # Agent 作成
        agent = Agent(
            role="Researcher",
            goal="CrewAIに関する情報を集める",
            backstory="CrewAIの基本的な機能をテストするのを手伝うAIです。"
        )

        # Task 作成
        task = Task(
            description="CrewAIが何か、その目的を要約する。",
            agent=agent,
            expected_output="CrewAIの概要とその目的についての簡潔な要約。"
        )

        # Crew 作成 & 実行
        crew = Crew(agents=[agent], tasks=[task])
        result = crew.kickoff()

        logger.info("=== CrewAI Test Result ===")
        logger.info(result)
        print("CrewAI test executed. Check log/test_crewai.log for details.")

    except Exception as e:
        logger.error("エラーが発生しました", exc_info=True)
        print(f"エラー: {e}")

if __name__ == "__main__":
    main()