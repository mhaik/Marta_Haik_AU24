import os
from pathlib import Path
from random import choice, seed
from collections import Counter
import requests
from requests.exceptions import RequestException
from typing import List, Union

# Define paths
S5_PATH = Path(os.path.realpath(__file__)).parent

PATH_TO_NAMES = S5_PATH / "names.txt"
PATH_TO_SURNAMES = S5_PATH / "last_names.txt"
PATH_TO_OUTPUT = S5_PATH / "sorted_names_and_surnames.txt"
PATH_TO_TEXT = S5_PATH / "random_text.txt"
PATH_TO_STOP_WORDS = S5_PATH / "stop_words.txt"

# Task 1
def task_1():
    seed(1)  # Set seed for reproducibility

    try:
        # Read and process names
        with open(PATH_TO_NAMES, "r", encoding="utf-8") as names_file:
            names = sorted([name.strip().lower() for name in names_file])

        # Read and process surnames
        with open(PATH_TO_SURNAMES, "r", encoding="utf-8") as surnames_file:
            surnames = [surname.strip().lower() for surname in surnames_file]

        # Assign random surnames to names
        with open(PATH_TO_OUTPUT, "w", encoding="utf-8") as output_file:
            for name in names:
                output_file.write(f"{name} {choice(surnames)}\n")

    except FileNotFoundError as e:
        print(f"File not found: {e}")

def task_2(top_k: int):
    try:
        # Read random text
        with open(PATH_TO_TEXT, "r", encoding="utf-8") as text_file:
            text = text_file.read().lower()

        # Read stop words
        with open(PATH_TO_STOP_WORDS, "r", encoding="utf-8") as stop_words_file:
            stop_words = set(word.strip() for word in stop_words_file)

        # Preprocess text: Retain only alphabetic tokens and remove stop words
        words = [
            word.strip(".,!?;:\"'") for word in text.split()
            if word.strip(".,!?;:\"'").isalpha() and word not in stop_words
        ]

        # Debugging: Output all instances of "far"
        print([word for word in text.split() if "far" in word])

        # Count word frequencies
        word_counts = Counter(words)

        # Debugging: Print frequency of "far"
        print(f"Frequency of 'far': {word_counts['far']}")

        # Get the top_k words
        return word_counts.most_common(top_k)

    except FileNotFoundError as e:
        print(f"File not found: {e}")
        return []



# Task 3
def task_3(url: str):
    try:
        response = requests.get(url)
        response.raise_for_status()
        return response
    except RequestException as e:
        raise RequestException(f"Request failed: {e}")

# Task 4
def task_4(data: List[Union[int, str, float]]):
    total = 0
    for item in data:
        try:
            total += float(item)
        except (ValueError, TypeError):
            print(f"Cannot convert {item} to float.")
    return total

# Task 5
def task_5():
    try:
        x, y = input("Enter two numbers separated by space: ").split()
        x = float(x)
        y = float(y)
        if y == 0:
            print("Can't divide by zero")
        else:
            print(x / y)
    except ValueError:
        print("Entered value is wrong")
