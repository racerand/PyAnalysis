import ast

def if_exists(node, func):
    if node:
        return func(node)
