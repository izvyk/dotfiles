#!/usr/bin/env python3

# import subprocess
from pyquery import PyQuery
# import json
import os

# original code https://gist.github.com/Surendrajat/ff3876fd2166dd86fb71180f4e9342d7
# weather icons
weather_icons = {
    "sunnyDay": "",
    "clearNight": "",
    "cloudyFoggyDay": "",
    "cloudyFoggyNight": "",
    "rainyDay": "",
    "rainyNight": "",
    "snowyIcyDay": "",
    "snowyIcyNight": "",
    "severe": "",
    "default": "",
}

# get location_id
# to get your own location_id, go to https://weather.com & search your location.
# once you choose your location, you can see the location_id in the URL(64 chars long hex string)
# like this: https://weather.com/en-PH/weather/today/l/bca47d1099e762a012b9a139c36f30a0b1e647f69c0c4ac28b537e7ae9c1c200
location_id = "f375a1521b5fb19e31b875b920448c798d73817e116d216c36e495e1676cd6b6" #Augsburg

# get html page
# https://weather.com/en-MT/weather/today/l/f375a1521b5fb19e31b875b920448c798d73817e116d216c36e495e1676cd6b6
# https://weather.com/en-MT/weather/today/l/f375a1521b5fb19e31b875b920448c798d73817e116d216c36e495e1676cd6b6
url = "https://weather.com/en-MT/weather/today/l/" + location_id
html_data = PyQuery(url=url)

# current temperature
temp = html_data("span[data-testid='TemperatureValue']").eq(0).text()
# print(temp)

# current status phrase
status = html_data("div[data-testid='wxPhrase']").text()
status = f"{status[:16]}.." if len(status) > 17 else status
# print(status)

# status code
status_code = html_data("#regionHeader").attr("class").split(" ")[2].split("-")[2]
# print(status_code)

# status icon
icon = (
    weather_icons[status_code]
    if status_code in weather_icons
    else weather_icons["default"]
)
# print(icon)

# temperature feels like
temp_feel = html_data(
    "div[data-testid='FeelsLikeSection'] > span > span[data-testid='TemperatureValue']"
).text()
temp_feel_text = f"Feels like {temp_feel}c"
# print(temp_feel_text)

# min-max temperature
temp_min = (
    html_data("div[data-testid='wxData'] > span[data-testid='TemperatureValue']")
    .eq(0)
    .text()
)
temp_max = (
    html_data("div[data-testid='wxData'] > span[data-testid='TemperatureValue']")
    .eq(1)
    .text()
)
dew_point = html_data("section[data-testid='TodaysDetailsModule'] span[data-testid='TemperatureValue']").eq(3).text()


# wind speed
wind_speed = html_data("span[data-testid='Wind']").text().split("\n")[1]
wind_text = f"  {wind_speed}"

# humidity
humidity = html_data("span[data-testid='PercentageValue']").text()
humidity_text = f"  {humidity}"

# visibility
visbility = html_data("span[data-testid='VisibilityValue']").text()
visbility_text = f"  {visbility}"

# air quality index
air_quality_index = html_data("text[data-testid='DonutChartValue']").text()
pressure = html_data("span[data-testid='PressureValue']").text().split("\n")[1]

sunrise_time = html_data("div[data-testid='SunriseValue'] p").text()
sunset_time = html_data("div[data-testid='SunsetValue'] p").text()

moon_phase = html_data("div[data-testid='wxData']").eq(7).text()
match moon_phase:
    case "Full Moon":
        moon_icon = "󰽢" # 
    case "Waning Gibbous":
        moon_icon = "󰽦" # 
    case "Third Quarter": #Last Quarter
        moon_icon = "󰽣" # 
    case "Waning Crescent":
        moon_icon = "󰽥" # 
    case "New Moon":
        moon_icon = "󰽤" # 
    case "Waxing Crescent":
        moon_icon = "󰽧" # 
    case "First Quarter":
        moon_icon = "󰽡" # 
    case "Waxing Gibbous":
        moon_icon = "󰽨" # 
    case _:
        moon_icon = "FIX NEEDED"


# hourly rain prediction
prediction = html_data("section[aria-label='Hourly Forecast']")(
    "div[data-testid='SegmentPrecipPercentage'] > span"
).text()
prediction = prediction.replace("Chance of Rain", "")
prediction = f"\n\n (hourly) {prediction}" if len(prediction) > 0 else prediction
# print(prediction)

# tooltip text
# tooltip_text = str.format(
#     "\t\t{}\t\t\n{}\n{}\n{}\n\n{}\n{}\n{}{}",
#     f'<span size="xx-large">{temp}</span>',
#     f"<big> {icon}</big>",
#     f"<b>{status}</b>",
#     f"<small>{temp_feel_text}</small>",
#     f"<b>{temp_min_max}</b>",
#     f"{wind_text}\t{humidity_text}",
#     f"{visbility_text}\tAQI {air_quality_index}",
#     f"<i> {prediction}</i>",
# )

# # print waybar module data
# out_data = {
#     "text": f"{icon} {temp}",
#     "alt": status,
#     "tooltip": tooltip_text,
#     "class": status_code,
# }
#print(json.dumps(out_data))

simple_weather =f"{icon}  {status}\n" + \
                f"  {temp} ({temp_feel_text})\n" + \
                f"  {temp_min}\t  {temp_max}\n" + \
                f"° {dew_point}\n" + \
                f"󰡍  {pressure}\n" + \
                f"{wind_text}\n" + \
                f"{humidity_text}\n" + \
                f"  {sunrise_time}\t   {sunset_time}\n" + \
                f"{moon_icon}  {moon_phase}\n" + \
                f"{visbility_text}  AQI {air_quality_index}"

try:
    with open(os.path.expanduser("~/.cache/.weather_cache"), "w") as file:
        file.write(simple_weather)
    print(simple_weather, end='')
except:
    pass
