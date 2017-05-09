import os
import sys
import telepot
import requests
import re
import datetime
from time import sleep
from bs4 import BeautifulSoup
from settings import token, start_msg


def handle(msg):
    content_type, chat_type, chat_id = telepot.glance(msg)

    chat_id = msg['chat']['id']
    command_input = msg['text']

    if command_input == '/start':
        bot.sendMessage(chat_id, start_msg)

    try:
        date = command_input.split()[1]
        command_input = command_input.split()[0]
    except:
        now = datetime.datetime.now()
        date = now.strftime("%d-%m-%Y")

    if command_input == '/duca':
        date1 = convertDate(date)

        payload = {'mensa': 'DUCA', 'da': date1, 'a': date1}
        msg = getMenu(payload)

        bot.sendMessage(chat_id, '🗓️Mensa Duca - {0}\n\n{1}'.format(date,
                        msg[0]))
        bot.sendMessage(chat_id, msg[1])

    if command_input == '/tridente':
        date1 = convertDate(date)

        payload = {'mensa': 'TRIDENTE', 'da': date1, 'a': date1}
        msg = getMenu(payload)

        bot.sendMessage(chat_id, '🗓️Mensa Tridente - {0}\n\n{1}'.format(date,
                        msg[0]))
        bot.sendMessage(chat_id, msg[1])

    if command_input == '/allergeni':
        bot.sendMessage(chat_id,
                        'http://menu.ersurb.it/menum/Allergeni_legenda.png')

    if command_input == '/credits':
        bot.sendMessage(chat_id, "Developed by:\n"
                                 "https://github.com/Radeox\n"
                                 "https://github.com/Fast0n")

    if command_input == '/status':
        bot.sendMessage(chat_id, "Running :)")


def getMenu(payload):
    r = requests.post("http://menu.ersurb.it/menum/menu.asp", data=payload)

    status = False
    rvp = '☀️Pranzo:\n'
    rvc = '🌙Cena:\n'
    rv0 = '\n🍝Primi:\n'
    rv1 = '\n🍖Secondi:\n'
    rv2 = '\n🍟Contorno:\n'
    rv3 = '\n🍨Frutta/Dolce:\n'

    soup = BeautifulSoup(r.text, 'html.parser')

    for link in soup.find_all('a'):
        try:
            app = link.get('onclick')
            m = re.findall('(".*?")', app)

            if m[1].replace('"', '') == '40' and not status:
                status = True
            elif m[1].replace('"', '') == '10' and status:
                status = False
                rvp += rv0 + rv1 + rv2 + rv3
                rv0 = '\n🍝Primi:\n'
                rv1 = '\n🍖Secondi:\n'
                rv2 = '\n🍟Contorno:\n'
                rv3 = '\n🍨Frutta/Dolce:\n'

            if m[1].replace('"', '') == '10':
                rv0 += ' • ' + m[2].replace('"', '') + '\n'
            elif m[1].replace('"', '') == '20':
                rv1 += ' • ' + m[2].replace('"', '') + '\n'
            elif m[1].replace('"', '') == '30':
                rv2 += ' • ' + m[2].replace('"', '') + '\n'
            elif m[1].replace('"', '') == '40':
                rv3 += ' • ' + m[2].replace('"', '') + '\n'
        except:
            pass

    rvc += rv0 + rv1 + rv2 + rv3

    return [rvp, rvc]


def convertDate(date):
    x, y, z = date.split('-')
    rv = y + '-' + x + '-' + z

    return rv


# Main
print("Starting UnimensaBot...")

# PID file
pid = str(os.getpid())
pidfile = "/tmp/unimensabot.pid"

# Check if PID exist
if os.path.isfile(pidfile):
    print("%s already exists, exiting!" % pidfile)
    sys.exit()

# Create PID file
f = open(pidfile, 'w')
f.write(pid)

# Start working
try:
    bot = telepot.Bot(token)
    bot.message_loop(handle)

    while 1:
        sleep(10)
finally:
    os.unlink(pidfile)