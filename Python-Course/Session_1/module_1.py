from typing import List


def task_1(array: List[int], target: int) -> List[int]:
    seen_numbers = {}
    for num in array:
        complement = target - num
        if complement in seen_numbers:
            return [complement, num]
        seen_numbers[num] = True
    return []


def task_2(number: int) -> int:
    reversed_number = 0
    is_negative = number < 0
    number = abs(number)

    while number > 0:
        digit = number % 10
        reversed_number = reversed_number * 10 + digit
        number //= 10
    return -reversed_number if is_negative else reversed_number


def task_3(array: List[int]) -> int:
    for i in range(len(array)):
        index = abs(array[i]) - 1
        if array[index] < 0:
            return abs(array[i])
        array[index] = -array[index]
    return -1


def task_4(string: str) -> int:
    roman_to_int = {
        'I': 1, 'V': 5, 'X': 10, 'L': 50,
        'C': 100, 'D': 500, 'M': 1000
    }
    total = 0
    prev_value = 0

    for char in reversed(string):
        current_value = roman_to_int[char]
        if current_value < prev_value:
            total -= current_value
        else:
            total += current_value
        prev_value = current_value

    return total


def task_5(array: List[int]) -> int:
    smallest = array[0]
    for num in array[1:]:
        if num < smallest:
            smallest = num
    return smallest
