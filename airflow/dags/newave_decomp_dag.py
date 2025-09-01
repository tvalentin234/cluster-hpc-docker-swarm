
from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash import BashOperator
import requests, time, os

PUSHGATEWAY = os.environ.get("PUSHGATEWAY_URL", "http://pushgateway:9091")

def push_metric(job, status):
    ts = int(time.time())
    payload = f'pipeline_status{{job="{job}"}} {1 if status=="ok" else 0}\n' \              f'push_time_seconds {ts}\n'
    requests.post(f"{PUSHGATEWAY}/metrics/job/{job}", data=payload)

default_args = {
    "owner": "atlas",
    "retries": 0,
    "retry_delay": timedelta(minutes=5),
}

with DAG(
    dag_id="newave_decomp_pipeline",
    schedule="@daily",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    default_args=default_args,
    tags=["atlas", "hpc"],
) as dag:

    start = BashOperator(
        task_id="start",
        bash_command=f'python3 -c "import requests; requests.post(\"{PUSHGATEWAY}/metrics/job/start\", data=\"push_time_seconds {{}}\".format(__import__(\"time\").time()))"',
    )

    newave = BashOperator(
        task_id="run_newave",
        bash_command="bash /opt/airflow/dags/wrappers/newave_wrapper.sh",
        env={"PUSHGATEWAY_URL": PUSHGATEWAY},
    )

    decomp = BashOperator(
        task_id="run_decomp",
        bash_command="bash /opt/airflow/dags/wrappers/decomp_wrapper.sh",
        env={"PUSHGATEWAY_URL": PUSHGATEWAY},
    )

    end = BashOperator(
        task_id="end",
        bash_command=f'python3 -c "import requests; requests.post(\"{PUSHGATEWAY}/metrics/job/end\", data=\"push_time_seconds {{}}\".format(__import__(\"time\").time()))"',
    )

    start >> newave >> decomp >> end
