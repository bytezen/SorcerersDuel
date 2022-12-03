def main():
    G = Game()
    _count = 10

    while True and _count > 0:
        G.run()

        _count -= 1


if __name__ == '__main__':
    from game import Game
    main()


