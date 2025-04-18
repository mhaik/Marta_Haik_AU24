"""
Module for preparing inverted indexes based on uploaded documents
"""

import sys
from argparse import ArgumentParser, ArgumentTypeError, FileType
from io import TextIOWrapper
from typing import Dict, List
import json

DEFAULT_PATH_TO_STORE_INVERTED_INDEX = "inverted.index"


class EncodedFileType(FileType):
    """File encoder"""

    def __call__(self, string):
        # the special argument "-" means sys.std{in,out}
        if string == "-":
            if "r" in self._mode:
                stdin = TextIOWrapper(sys.stdin.buffer, encoding=self._encoding)
                return stdin
            if "w" in self._mode:
                stdout = TextIOWrapper(sys.stdout.buffer, encoding=self._encoding)
                return stdout
            msg = 'argument "-" with mode %r' % self._mode
            raise ValueError(msg)

        # all other arguments are used as file names
        try:
            return open(string, self._mode, self._bufsize, self._encoding, self._errors)
        except OSError as exception:
            args = {"filename": string, "error": exception}
            message = "can't open '%(filename)s': %(error)s"
            raise ArgumentTypeError(message % args)

    def print_encoder(self):
        """printer of encoder"""
        print(self._encoding)


class InvertedIndex:
    """
    This module is necessary to extract inverted indexes from documents.
    """

    def __init__(self, words_ids: Dict[str, List[int]]):
        self.words_ids = words_ids  # Saving the word mapping when creating the class

    def query(self, words: List[str]) -> List[int]:
        """Return the list of relevant documents for the given query"""
        nested_list = [] # List to hold document IDs for each word
        for word in words:
            if word in self.words_ids:
                nested_list.append(self.words_ids[word])

        unique_elements = set() # Set to get unique document IDs
        for sublist in nested_list:
            for item in sublist:
                unique_elements.add(item)

        return list(unique_elements) # Conversion back into list
    
    
    def dump(self, filepath: str) -> None:
        """
        Allow us to write inverted indexes documents to temporary directory or local storage
        :param filepath: path to file with documents
        :return: None
        """
        # Opening the file, write the index as JSON
        with open(filepath, "w", encoding="utf-8") as json_file:
            json.dump(self.words_ids, json_file, ensure_ascii=False, indent=4)
        

    @classmethod
    def load(cls, filepath: str):
        """
        Allow us to upload inverted indexes from either temporary directory or local storage
        :param filepath: path to file with documents
        :return: InvertedIndex
        """
        # Opening the file, read the JSON data
        with open(filepath, "r", encoding="utf-8") as json_file:
            words_ids = json.load(json_file)

        return cls(words_ids) # New InvertedIndex object with the loaded data


def load_documents(filepath: str) -> Dict[int, str]:
    """
    Allow us to upload documents from either tempopary directory or local storage
    :param filepath: path to file with documents
    :return: Dict[int, str]
    """
    documents = {}  # Dictionary for storing documents

    with open(filepath, 'r', encoding='utf-8') as text:
        for line in text:
            doc_id, content = line.lower().split("\t", 1) # Splitting each line into a document ID and its content
            doc_id = int(doc_id)  # Converting ID to integer
            documents[doc_id] = content.strip()  # Adding content to the dictionary

    return documents


def build_inverted_index(documents: Dict[int, str]) -> InvertedIndex:
    """
    Builder of inverted indexes based on documents
    :param documents: dict with documents
    :return: InvertedIndex class
    """
    words_ids = {}  # Dictionary to store index

    for doc_id, content in documents.items():
        for word in content.split(' '):
            if word not in words_ids:  # If the word is not in the index, add it
                words_ids[word] = set()  # Set to avoid duplicate IDs
            words_ids[word].add(doc_id)  # Adding the current document ID
            
    for word in words_ids:
        words_ids[word] = list(words_ids[word]) # Sets into lists (JSON doesn't support sets)

    return InvertedIndex(words_ids)


def callback_build(arguments) -> None:
    """process build runner"""
    return process_build(arguments.dataset, arguments.output)


def process_build(dataset, output) -> None:
    """
    Function is responsible for running of a pipeline to load documents,
    build and save inverted index.
    :param arguments: key/value pairs of arguments from 'build' subparser
    :return: None
    """
    documents: Dict[int, str] = load_documents(dataset)
    inverted_index = build_inverted_index(documents)
    inverted_index.dump(output)


def callback_query(arguments) -> None:
    """ "callback query runner"""
    process_query(arguments.query, arguments.index)


def process_query(queries, index) -> None:
    """
    Function is responsible for loading inverted indexes
    and printing document indexes for key words from arguments.query
    :param arguments: key/value pairs of arguments from 'query' subparser
    :return: None
    """
    inverted_index = InvertedIndex.load(index)
    for query in queries:
        print(query[0])
        if isinstance(query, str):
            query = query.strip().split()

        doc_indexes = ",".join(str(value) for value in inverted_index.query(query))
        print(doc_indexes)


def setup_subparsers(parser) -> None:
    """
    Initial subparsers with arguments.
    :param parser: Instance of ArgumentParser
    """
    subparser = parser.add_subparsers(dest="command")
    build_parser = subparser.add_parser(
        "build",
        help="this parser is need to load, build"
        " and save inverted index bases on documents",
    )
    build_parser.add_argument(
        "-d",
        "--dataset",
        required=True,
        help="You should specify path to file with documents. ",
    )
    build_parser.add_argument(
        "-o",
        "--output",
        default=DEFAULT_PATH_TO_STORE_INVERTED_INDEX,
        help="You should specify path to save inverted index. "
        "The default: %(default)s",
    )
    build_parser.set_defaults(callback=callback_build)

    query_parser = subparser.add_parser(
        "query", help="This parser is need to load and apply inverted index"
    )
    query_parser.add_argument(
        "--index",
        default=DEFAULT_PATH_TO_STORE_INVERTED_INDEX,
        help="specify the path where inverted indexes are. " "The default: %(default)s",
    )
    query_file_group = query_parser.add_mutually_exclusive_group(required=True)
    query_file_group.add_argument(
        "-q",
        "--query",
        dest="query",
        action="append",
        nargs="+",
        help="you can specify a sequence of queries to process them overall",
    )
    query_file_group.add_argument(
        "--query_from_file",
        dest="query",
        type=EncodedFileType("r", encoding="utf-8"),
        # default=TextIOWrapper(sys.stdin.buffer, encoding='utf-8'),
        help="query file to get queries for inverted index",
    )
    query_parser.set_defaults(callback=callback_query)


def main():
    """
    Starter of the pipeline
    """
    parser = ArgumentParser(
        description="Inverted Index CLI is need to load, build,"
        "process query inverted index"
    )
    setup_subparsers(parser)
    arguments = parser.parse_args()
    arguments.callback(arguments)


if __name__ == "__main__":
    main()

# python final_task.py build --dataset wikipedia_sample --output inverted.index
# python final_task.py query --index inverted.index --query a Greek
# python final_task.py query --index inverted.index --query_from_file simple_queries.txt