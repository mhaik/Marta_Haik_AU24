from collections import defaultdict
from itertools import product
from typing import Any, Dict, List, Tuple

def task_1(data_1: Dict[str, int], data_2: Dict[str, int]) -> Dict[str, int]:
    result = data_1.copy()
    for key, value in data_2.items():
        result[key] = result.get(key, 0) + value
    return result

def task_2() -> Dict[int, int]:
    return {i: i ** 2 for i in range(1, 16)}

def task_3(data: Dict[Any, List[str]]) -> List[str]:
    keys = list(data.keys())
    values = [data[key] for key in keys]
    return ["".join(combination) for combination in product(*values)]

def task_4(data: Dict[str, int]) -> List[str]:
    if not data:
        return []
    return [k for k, v in sorted(data.items(), key=lambda item: item[1], reverse=True)[:3]]

def task_5(data: List[Tuple[Any, Any]]) -> Dict[str, List[int]]:
    result = defaultdict(list)
    for key, value in data:
        result[key].append(value)
    return dict(result)

def task_6(data: List[Any]) -> List[Any]:
    return list(dict.fromkeys(data))

def task_7(words: List[str]) -> str:
    if not words:
        return ""
    prefix = words[0]
    for word in words[1:]:
        while not word.startswith(prefix):
            prefix = prefix[:-1]
            if not prefix:
                return ""
    return prefix

def task_8(haystack: str, needle: str) -> int:
    if needle == "":
        return 0
    return haystack.find(needle)