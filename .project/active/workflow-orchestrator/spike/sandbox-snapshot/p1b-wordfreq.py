import argparse
import re
import sys
from collections import Counter

STOPWORDS = frozenset({
    "a", "an", "the", "and", "or", "but", "if", "then", "else", "of", "to",
    "in", "on", "at", "by", "for", "with", "about", "against", "between",
    "into", "through", "during", "before", "after", "above", "below", "from",
    "up", "down", "out", "off", "over", "under", "again", "further", "once",
    "here", "there", "when", "where", "why", "how", "all", "any", "both",
    "each", "few", "more", "most", "other", "some", "such", "no", "nor",
    "not", "only", "own", "same", "so", "than", "too", "very", "s", "t",
    "can", "will", "just", "don", "should", "now", "is", "are", "was",
    "were", "be", "been", "being", "have", "has", "had", "having", "do",
    "does", "did", "doing", "it", "its", "this", "that", "these", "those",
    "i", "me", "my", "myself", "we", "our", "ours", "ourselves", "you",
    "your", "yours", "yourself", "yourselves", "he", "him", "his", "himself",
    "she", "her", "hers", "herself", "they", "them", "their", "theirs",
    "themselves", "what", "which", "who", "whom", "as", "until", "while",
})

WORD_RE = re.compile(r"[a-z0-9']+")


def top_words(text, n=10):
    tokens = (t for t in WORD_RE.findall(text.lower()) if t not in STOPWORDS)
    counts = Counter(tokens)
    return sorted(counts.items(), key=lambda item: (-item[1], item[0]))[:n]


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Show the most frequent words in a UTF-8 text file."
    )
    parser.add_argument("path", help="path to a UTF-8 text file")
    parser.add_argument(
        "--top", type=int, default=10, help="number of words to show (default: 10)"
    )
    args = parser.parse_args(argv)

    try:
        with open(args.path, "r", encoding="utf-8") as f:
            text = f.read()
    except FileNotFoundError:
        print(f"Error: file not found: {args.path}", file=sys.stderr)
        sys.exit(1)
    except UnicodeDecodeError:
        print(f"Error: {args.path} is not valid UTF-8", file=sys.stderr)
        sys.exit(1)

    for word, count in top_words(text, args.top):
        print(f"{word} {count}")


if __name__ == "__main__":
    main()
