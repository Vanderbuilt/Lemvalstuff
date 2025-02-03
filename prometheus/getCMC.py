#!/usr/bin/python3
#
# gets Coin Market Cap data for LEMX and formats for prometheus file exporter
#
from requests import Request, Session
from requests.exceptions import ConnectionError, Timeout, TooManyRedirects
import json

url = 'https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest'
parameters = {
  'symbol':'LEMX',
  'convert':'USD'

}
headers = {
  'Accepts': 'application/json',
  'X-CMC_PRO_API_KEY': '********<ADD YOUR API KEY BETWEEN THE SINGLE QUOTES>*********',
}

session = Session()
session.headers.update(headers)

try:
  response = session.get(url, params=parameters)
  data = json.loads(response.text)
  lemx = data["data"]["LEMX"]
  quote = data["data"]["LEMX"]["quote"]["USD"]

  for key in lemx:
      if type(lemx[key]) == int:
          name = "lemx_" + key
          print(name, lemx[key])
  for key in quote:
      if type(quote[key]) == int or isinstance(quote[key], float):
          name = "lemx_quote_" + key
          print(name, quote[key])

except (ConnectionError, Timeout, TooManyRedirects) as e:
  print(e)
