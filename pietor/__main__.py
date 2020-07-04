#!/bin/python3
import sys
from sys import argv
from curses import wrapper
import curses

def main(stdscr):
    # Clear screen
    stdscr.clear()

    # No (n)ew(l)ine
    #curses.nonl()

    # This raises ZeroDivisionError when i == 10.
#    for i in range(0, 10):
#        v = i-10
#        stdscr.addstr(i, 0, '10 divided by {} is {}'.format(v, 10/v))

    stdscr.box()
    curses.curs_set(1)
    stdscr.addstr(0,1,"File\tEdit\tView")
    stdscr.refresh()
    #stdscr.getkey()
    pos = 1
    row = 2
    isTab = False
    newflag = False
    haveErased = False
    outstring = ""
    forbiddensyms =  ["\002", "\007", "\x0d", "\x09", "KEY_BACKSPACE"]
    while True:
        k = stdscr.getkey()
        if not newflag:
            stdscr.addstr(0, 40, "{}, {}".format(pos, row))
            stdscr.addstr(0, 38, "─")
        else:
            stdscr.addstr(0, 38, "N")
            stdscr.addstr(0, 40, "{}, {}".format(pos, row))
        if not (k == 'aljkdkajsd'):
            if pos == (curses.COLS - 1):
                pos = 1
                col += 1
            elif k == '\007':
                outstring += "Ding!"
                pos += 5
            elif k == '\x09':
                stdscr.move(row, pos-1)
                pos += 4
                newflag = True
                isTab = True
                stdscr.move(row, pos)
            elif k == '\002':
                newflag = True
                pos = 1
                row += 1
                stdscr.move(row,2)
            elif k == "KEY_BACKSPACE":
                haveErased = True
                if isTab:
                    for i in range(pos-2, pos):
                        stdscr.delch(row, i)
                        pos -= 1
                        isTab = False
                        outstring = outstring[:-4]
                else:
                    #stdscr.delch(row, pos)
                    stdscr.addch(row, pos, " ")
                    #curses.doupdate()
                    pos -= 1
                    outstring = outstring[:-1]
                stdscr.move(row, pos+1)
            elif k == '\x0d' or k == '\n':
                newflag = True
                pos = 1
                row += 1
                stdscr.refresh()
            elif (len(k) == 1) and not (k in forbiddensyms):
                newflag = False
                outstring += k
                if not haveErased:
                    pos += 1
                else:
                    pos -= 1
                    haveErased = False
                    #pos = pos
                stdscr.addch(row, pos, k)
            #else:
            #    raise Exception("Bad value: {}, {}".format(k, type(k)))
        #stdscr.addstr(row,1,outstring)

wrapper(main)

if __name__ == '__main__':
    wrapper(main)
