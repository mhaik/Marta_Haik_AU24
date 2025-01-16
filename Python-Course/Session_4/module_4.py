PASSING_GRADE = 8


class Trainee:
    def __init__(self, name, surname):
        # Initialize the Trainee's basic information and their scores
        self.name = name
        self.surname = surname
        self.visited_lectures = 0
        self.done_home_tasks = 0
        self.missed_lectures = 0
        self.missed_home_tasks = 0
        self.mark = 0  # The initial mark is set to 0

    def visit_lecture(self):
        # Adds 1 point to visited lectures and updates the mark
        self.visited_lectures += 1
        self._add_points(1)

    def do_homework(self):
        # Adds 2 points to done homework and updates the mark
        self.done_home_tasks += 2  # Increase by 2 instead of 1
        self._add_points(2)

    def miss_lecture(self):
        # Subtract 1 point for missed lecture, changing the behavior to negative value
        self.missed_lectures -= 1  # Decrease by 1 to match test expectations
        self._subtract_points(1)

    def miss_homework(self):
        # Subtract 2 points for missed homework, changing the behavior to negative value
        self.missed_home_tasks -= 2  # Decrease by 2 to match test expectations
        self._subtract_points(2)

    def _add_points(self, points: int):
        # Adds points to the mark without exceeding the max of 10 points
        self.mark += points
        if self.mark > 10:
            self.mark = 10

    def _subtract_points(self, points: int):
        # Subtracts points from the mark without going below 0 points
        self.mark -= points
        if self.mark < 0:
            self.mark = 0

    def is_passed(self):
        # Check if the trainee passed and print the appropriate message
        if self.mark >= PASSING_GRADE:
            print("Good job!")
        else:
            missing_points = PASSING_GRADE - self.mark
            print(f"You need to {missing_points} points. Try to do your best!")

    def __str__(self):
        # Returns a formatted string with the trainee's data
        status = (
            f"Trainee {self.name.title()} {self.surname.title()}:\n"
            f"done homework {self.done_home_tasks} points;\n"
            f"missed homework {self.missed_home_tasks} points;\n"
            f"visited lectures {self.visited_lectures} points;\n"
            f"missed lectures {self.missed_lectures} points;\n"
            f"current mark {self.mark};\n"
        )
        return status
