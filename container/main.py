import boto3
import requests

if __name__ == "__main__":

    print("Hello from container")

    s3 = boto3.client("s3")
    response = s3.list_buckets()

    # Get a list of all bucket names: bucket_list
    bucket_list = [bucket["Name"] for bucket in response["Buckets"]]
    print(bucket_list)
    print("\n")

    response = requests.get("https://jsonplaceholder.typicode.com/todos/1")

    print(f"Status Code: {response.status_code}")
    print(response.text[:500])

    print("Good bye from container")
