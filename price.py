import sys

def get_price(gas, gasPrice, etherPrice):
    return int(gas) * float(gasPrice) * .000000001 * float(etherPrice)

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('Usage: python3 price.py <gas> <gasPrice> <etherPrice>')
        sys.exit(1)
    print('$' + str(round(get_price(sys.argv[1], sys.argv[2], sys.argv[3]), 2)))