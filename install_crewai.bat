@echo off
setlocal

echo ============================================
echo Step 1: Check Docker installation
echo ============================================
docker --version
if errorlevel 1 (
    echo Docker is not installed or not in PATH.
    pause
    exit /b
)

echo ============================================
echo Step 2: Create Dockerfile
echo ============================================
(
echo FROM python:3.11-slim
echo WORKDIR /app
echo ENV DEBIAN_FRONTEND=noninteractive
echo RUN apt-get update && apt-get install -y git curl build-essential
echo RUN python -m pip install --upgrade pip
echo RUN pip install crewai crewai-tools openai==1.99.9
echo COPY test_crewai.py /app/test_crewai.py
echo RUN mkdir -p /app/log
) > Dockerfile_CrewAI

echo ============================================
echo Step 3: Create test_crewai.py
echo ============================================
(
echo import os
echo import logging
echo from crewai import Agent, Task, Crew
echo.
echo logging.basicConfig(
echo filename="log/test_crewai.log",
echo filemode="w",
echo level=logging.INFO,
echo format="%(asctime)s [%(levelname)s] %(message)s"
echo )
echo.
echo logger = logging.getLogger(__name__)
echo.
echo os.environ['CREWAI_SKIP_TRACE_CONFIRM'] = 'true'
echo.
echo def main():
echo     try:
echo         # Agent 作成
echo         agent = Agent(
echo             role="Researcher",
echo             goal="CrewAIに関する情報を集める",
echo             backstory="CrewAIの基本的な機能をテストするのを手伝うAIです。"
echo         )
echo.
echo         # Task 作成
echo         task = Task(
echo             description="CrewAIが何か、その目的を要約する。",
echo             agent=agent,
echo             expected_output="CrewAIの概要とその目的についての簡潔な要約。"
echo         )
echo.
echo         # Crew 作成 & 実行
echo         crew = Crew(agents=[agent], tasks=[task])
echo         result = crew.kickoff()
echo.
echo         logger.info("=== CrewAI Test Result ===")
echo         logger.info(result)
echo         print("CrewAI test executed. Check log/test_crewai.log for details.")
echo.
echo     except Exception as e:
echo         logger.error("エラーが発生しました", exc_info=True)
echo         print(f"エラー: {e}")
echo.
echo if __name__ == "__main__":
echo     main()
) > test_crewai.py

echo ============================================
echo Step 4: Build Docker image
echo ============================================
docker build --no-cache -t crewai_image -f Dockerfile_CrewAI .

echo ============================================
echo Step 5: Run test script inside Docker
echo ============================================
docker run -it --rm -e OPENAI_API_KEY=%OPENAI_API_KEY% -v "%CD%\log:/app/log" crewai_image python /app/test_crewai.py

echo ============================================
echo CrewAI Docker setup complete!
echo ============================================
pause