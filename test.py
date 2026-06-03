from unittest.mock import patch
import unittest
from io import StringIO
import app


class TestFizzBuzz(unittest.TestCase):
    def test_fizzbuzz_length(self):
        with patch("sys.stdout", new_callable=StringIO) as mock_stdout:
            app.fizzbuzz()
            output = mock_stdout.getvalue().strip().split("\n")
            self.assertEqual(len(output), 100)

    def test_fizzbuzz_specific_values(self):
        with patch("sys.stdout", new_callable=StringIO) as mock_stdout:
            app.fizzbuzz()
            output = mock_stdout.getvalue().strip().split("\n")
            self.assertEqual(output[2], "Fizz")
            self.assertEqual(output[4], "Buzz")
            self.assertEqual(output[14], "FizzBuzz")
            self.assertEqual(output[0], "1")


class TestHealthCheck(unittest.TestCase):
    def setUp(self):
        self.client = app.app_instance.test_client()

    def test_healthcheck(self):
        response = self.client.get('/health')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data.decode(), "OK")


if __name__ == "__main__":
    unittest.main()
