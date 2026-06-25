import unittest
from app import app_instance


class TestFizzBuzzAPI(unittest.TestCase):
    def setUp(self):
        self.client = app_instance.test_client()

    def test_fizzbuzz_endpoint(self):
        # Test basic numbers
        response = self.client.get('/fizzbuzz/1')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json, {"number": 1, "result": "1"})

        response = self.client.get('/fizzbuzz/3')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json, {"number": 3, "result": "Fizz"})

        response = self.client.get('/fizzbuzz/5')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json, {"number": 5, "result": "Buzz"})

        response = self.client.get('/fizzbuzz/15')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json, {"number": 15, "result": "FizzBuzz"})

        # Test a larger range (e.g., 1 to 100)
        for i in range(1, 101):
            expected_result = ""
            if i % 15 == 0:
                expected_result = "FizzBuzz"
            elif i % 3 == 0:
                expected_result = "Fizz"
            elif i % 5 == 0:
                expected_result = "Buzz"
            else:
                expected_result = str(i)
            
            response = self.client.get(f'/fizzbuzz/{i}')
            self.assertEqual(response.status_code, 200)
            self.assertEqual(response.json["result"], expected_result)


class TestHealthCheck(unittest.TestCase):
    def setUp(self):
        self.client = app_instance.test_client()

    def test_healthcheck(self):
        response = self.client.get('/health')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data.decode(), "OK")


if __name__ == "__main__":
    unittest.main()
