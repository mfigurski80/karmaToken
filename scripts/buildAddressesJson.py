# /bin/python3

import sys;

if __name__ == '__main__':
  f_name = sys.argv[1];
  f = open(f_name, 'r');
  buf = f.read();
  print("{");
  first = True
  for net in buf.split('Network: ')[1:]:
    lines = net.split("\n")
    net_name = lines[0].split(' ')[0]
    if first:
      first = False
    else:
      print(',\n', end='');
    print(f'  "{net_name}": ' + '{', end='');

    net_id = lines[0].split("id: ")[1][:-1]
    print(f'\n    "id": {net_id}', end='')

    for line in lines[1:]:
      d = line.split(': ')
      if len(d) >= 2:
        print(f',\n    "{d[0].strip()}": "{d[1].strip()}"', end="")
    print('\n  }', end="")
    # print(lines[1:])
  print("\n}")
