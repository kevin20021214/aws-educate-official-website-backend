FROM --platform=linux/amd64 public.ecr.aws/lambda/python:3.11
# 1. 切到 /var/task
WORKDIR /var/task

# 2. 安裝依賴
COPY requirements.txt .
RUN pip install -r requirements.txt

# 3. 複製程式碼
COPY . .

# 4. 設定 Lambda handler
CMD ["lambda_function.lambda_handler"]
