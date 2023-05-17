
def ordinal(n: int):
    if 10 < (n % 100) < 14:
        suffix = "th"
    else:
        suffix = ["th", "st", "nd", "rd", "th", "th", "th", "th", "th", "th", "th"][n % 10]
    return f"{n}{suffix}"
