#!/usr/bin/env python3

import subprocess
import sys
import os

def simple_load_env(filepath=".env"):
  try:
    with open(filepath) as f:
      for line in f:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        value = value.strip().strip('\'"')
        os.environ[key] = value
  except FileNotFoundError:
    print(f"Error: {filepath} not found. Using existing environment variables. Aborting.")
    sys.exit(1)

class Orchestrator():
  def __init__(self, start_stop_arn: str, describe_arn: str, region: str = "us-east-1"):
    self.start_stop_arn = start_stop_arn
    self.describe_arn = describe_arn
    self.region = region

  def execute(self, option: str):
    if option == "s":
      cmds = ["./start.sh", self.start_stop_arn, self.describe_arn, self.region]
    elif option == "d":
      cmds = ["./teardown.sh", self.start_stop_arn, self.region]
    else:
      print("Invalid option. Aborting.")
      sys.exit(1)

    p = subprocess.Popen(
      cmds,
      stdout=subprocess.PIPE,
      stderr=subprocess.STDOUT,
      text=True,
      bufsize=1
    )

    for line in p.stdout:
      print(line, end="")

    code = p.wait()
    if code != 0:
      print(f"Command failed with exit code {code}")
      sys.exit(code)

if __name__ == "__main__":
  input_prompt = """
Would you like to start [s/S] or destroy [d/D]?
Input selection (any other inputs will be ignored): """

  choice = input(input_prompt).lower()
  if choice not in ["s", "d"]:
    print("Invalid selection. Aborting.")
    sys.exit(1)

  simple_load_env()

  rek_arn = os.environ.get("REKOGNITION_START_STOP_ARN")
  if not rek_arn:
    print("Missing Rekognition Custom Label ARN. Aborting.")
    sys.exit(1)

  proj_arn = os.environ.get("REKOGNITION_DESCRIBE_ARN")
  if not proj_arn:
    print("Missing Rekognition Custom Label Project ARN. Aborting.")
    sys.exit(1)

  region = os.environ.get("REGION", "us-east-1")

  o = Orchestrator(rek_arn, proj_arn, region)
  o.execute(choice)