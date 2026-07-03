import argparse
import re
import sys
from collections import Counter

STOPWORDS = frozenset({
    "a", "about", "above", "after", "again", "against", "all", "am", "an",
    "and", "any", "are", "aren't", "as", "at", "be", "because", "been",
    "before", "being", "below", "between", "both", "but", "by", "can't",
    "cannot", "could", "couldn't", "did", "didn't", "do", "does", "doesn't",
    "doing", "don't", "down", "during", "each", "few", "for", "from",
    "further", "had", "hadn't", "has", "hasn't", "have", "haven't", "having",
    "he", "he'd", "he'll", "he's", "her", "here", "here's", "hers",
    "herself", "him", "himself", "his", "how", "how's", "i", "i'd", "i'll",
    "i'm", "i've", "if", "in", "into", "is", "isn't", "it", "it's", "its",
    "itself", "let's", "me", "more", "most", "mustn't", "my", "myself",
    "no", "nor", "not", "of", "off", "on", "once", "only", "or", "other",
    "ought", "our", "ours", "ourselves", "out", "over", "own", "same",
    "shan't", "she", "she'd", "she'll", "she's", "should", "shouldn't",
    "so", "some", "such", "than", "that", "that's", "the", "their",
    "theirs", "them", "themselves", "then", "there", "there's", "these",
    "they", "they'd", "they'll", "they're", "they've", "this", "those",
    "through", "to", "too", "under", "until", "up", "very", "was",
    "wasn't", "we", "we'd", "we'll", "we're", "we've", "were", "weren't",
    "what", "what's", "when", "when's", "where", "where's", "which",
    "while", "who", "who's", "whom", "why", "why's", "with", "won't",
    "would", "wouldn't", "you", "you'd", "you'll", "you're", "you've",
    "your", "yours", "yourself", "yourselves",
})

DEFAULT_TOP = 10

_TOKEN_RE = re.compile(r"[a-z0-9']+")


def top_words(text, n=DEFAULT_TOP):
    tokens = (t for t in _TOKEN_RE.findall(text.lower()) if t not in STOPWORDS)
    counts = Counter(tokens)
    ranked = sorted(counts.items(), key=lambda pair: (-pair[1], pair[0]))
    return ranked[:n]


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Print the most frequent words in a UTF-8 text file."
    )
    parser.add_argument("path", help="path to a UTF-8 text file")
    parser.add_argument(
        "--top", type=int, default=DEFAULT_TOP,
        help="number of words to show (default: %(default)s)",
    )
    args = parser.parse_args(argv)

    try:
        with open(args.path, "r", encoding="utf-8") as f:
            text = f.read()
    except FileNotFoundError:
        print(f"error: file not found: {args.path}", file=sys.stderr)
        return 1
    except UnicodeDecodeError:
        print(f"error: {args.path} is not valid UTF-8", file=sys.stderr)
        return 1

    for word, count in top_words(text, args.top):
        print(f"{word} {count}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
