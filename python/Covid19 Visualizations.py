#####################################################################################################################################
# I explore COVID19 data in this project to look at global spread, infection rates, and infection intensity
# I use two methods to make it easier to compare data.
#   For one method, I use two y axes so the data can use different scales
#   For the second method, I normalize the data to be a fraction of the max value.

# Import necessary modules
from turtle import title
import pandas as pd
import numpy as np
import plotly.express as px
import matplotlib.pyplot as plt
import plotly.graph_objects as go
from plotly.subplots import make_subplots

# Loading the dataset
dataset_url = 'https://raw.githubusercontent.com/datasets/covid-19/master/data/countries-aggregated.csv'
df = pd.read_csv(dataset_url)

# check the shape of the dataframe
df.shape

# Preprocessing
# say I want all the rows where confirmed cases is more than zero
df = df[df.Confirmed > 0]

#####################################################################################################################################
# Create a plot to show Confirmed cases
fig = px.choropleth(df, locations = 'Country', locationmode='country names', color='Confirmed'
    ,animation_frame='Date')
fig = fig.update_layout(title_text = 'Global COVID19 Spread')
fig.show()                     # Turn this on to see the plot and interact with it.

# Same thing but show deaths
# Start with new dataframe that only has rows where deaths > 0
df_deaths = df[df.Deaths > 0]
# Create the plot
fig = px.choropleth(df_deaths, locations='Country', locationmode='country names', color='Deaths'
    ,animation_frame='Date')
fig = fig.update_layout(title_text = 'Global COVID19 Deaths')
fig.show()

#####################################################################################################################################
# Visualize intensity of COVID19 transmission in each country
# Using Daily New Cases as a metric.
# Starting with China
df_china = df[df.Country == 'China']
df_china.head()

df_china['Infection Change'] = df_china['Confirmed'].diff()
df_china['Infection Rate'] = df_china['Infection Change'] / df_china['Confirmed'] * 100
df_china.head()

# Plot confirmed infections, Daily new Cases, and Daily New Infection Rate (comp'd against total cases)
# Use secondary axis for rate (%)
infection_rate_fig = make_subplots(specs=[[{'secondary_y': True}]])
infection_rate_fig = infection_rate_fig.add_trace(
    go.Scatter(x=df_china['Date'], y = df_china['Confirmed'], name='Confirmed Cases'),
    secondary_y=False,
)
infection_rate_fig = infection_rate_fig.add_trace(
    go.Scatter(x=df_china['Date'], y = df_china['Infection Rate'], name='Infection Rate (%)'),
    secondary_y=True,
)
# Set figure and axis titles
infection_rate_fig = infection_rate_fig.update_layout(
    title_text = 'Covid19 - Confirmed Cases and Infection Rate for China'
)
infection_rate_fig = infection_rate_fig.update_xaxes(
    title_text = 'Date'
)
infection_rate_fig = infection_rate_fig.update_yaxes(
    title_text = 'Cases', secondary_y = False
)
infection_rate_fig = infection_rate_fig.update_yaxes(
    title_text = 'Infection Rate (%)', secondary_y = True
)
infection_rate_fig.show()

# Get the MAX number of new daily infections
df_china['Infection Change'].max()

#####################################################################################################################################
# Now to get it for all the countries.
# Get a list of countries, then create a list of the calculated max infection rate for each country. Append that list
countries = list(df['Country'].unique())
max_daily_infections = []
for c in countries:
    MIR = df[df.Country == c].Confirmed.diff().max()
    max_daily_infections.append(MIR)
print(max_daily_infections)

# Create a dataframe of the max daily new infections
df_MIR = pd.DataFrame()
df_MIR['Country'] = countries
df_MIR['Max Daily New Infections'] = max_daily_infections
df_MIR.head()

# Create a bar chart showing max daily new infections by country
# Y axis should be in a log scale so the small values are still visible
fig_bar = px.bar(df_MIR, x='Country', y='Max Daily New Infections', color='Country', title='Max Daily New Infections by Country', log_y=True)
fig_bar.show()

#####################################################################################################################################
# Next, see how Italy's national lockdown affected COVID19 Transmission
# Italy's lockdown started March 9th, 2020.

italy_ld_start = '2020-03-09'
italy_ld_one_month = '2020-04-09'

# Make an Italy-specific dataframe
df_italy = df[df.Country == 'Italy']
# Keep it to a reasonable timeframe so it's easier to see what's going on. Cut-off after Aug 2020
df_italy = df_italy[df_italy.Date < '2020-09-01']

# Calculate the daily new infections in Italy
df_italy['Daily New Infections'] = df_italy['Confirmed'].diff()

# Plot the data with the lockdown date called out
fig_italy = px.line(df_italy, x='Date', y='Daily New Infections', title='Daily New Infections Before and After Lockdown in Italy')
fig_italy = fig_italy.add_shape(
    dict(
        type='line',
        x0=italy_ld_start,
        y0=0,
        x1=italy_ld_start,
        y1=df_italy['Daily New Infections'].max(),
        line = dict(color='red',width=2)
    )
)
fig_italy = fig_italy.add_annotation(
    dict(
        x = italy_ld_start,
        y = df_italy['Daily New Infections'].max(),
        text = 'Lockdown Start Date'
    )
)
fig_italy = fig_italy.add_shape(
    dict(
        type='line',
        x0=italy_ld_one_month,
        y0=0,
        x1=italy_ld_one_month,
        y1=df_italy['Daily New Infections'].max(),
        line = dict(color='orange',width=2)

    )
)
fig_italy = fig_italy.add_annotation(
    dict(
        x = italy_ld_one_month,
        y = 0,
        text = 'Lockdown +1 Month'
    )
)
fig_italy.show()

# See how Italy's lockdown affects COVID19 Deaths
# Calculate Daily New Deaths
df_italy['Daily New Deaths'] = df_italy['Deaths'].diff()

fig_italy = px.line(df_italy, x='Date', y=['Daily New Infections','Daily New Deaths'])

# Normalize the data so it's easier to compare. Make it a percentage of the max of the daily new.
df_italy['Daily New Infections'] = df_italy['Daily New Infections']/df_italy['Daily New Infections'].max()
df_italy['Daily New Deaths'] = df_italy['Daily New Deaths']/df_italy['Daily New Deaths'].max()
# Add the Lockdown Start and End dates again.
fig_italy = px.line(df_italy, x='Date', y=['Daily New Infections','Daily New Deaths'])
fig_italy = fig_italy.add_shape(
    dict(
        type='line',
        x0=italy_ld_start,
        y0=0,
        x1=italy_ld_start,
        y1=df_italy['Daily New Infections'].max(),
        line = dict(color='red',width=2)
    )
)
fig_italy = fig_italy.add_annotation(
    dict(
        x = italy_ld_start,
        y = df_italy['Daily New Infections'].max(),
        text = 'Lockdown Start Date'
    )
)
fig_italy = fig_italy.add_shape(
    dict(
        type='line',
        x0=italy_ld_one_month,
        y0=0,
        x1=italy_ld_one_month,
        y1=df_italy['Daily New Infections'].max(),
        line = dict(color='orange',width=2)

    )
)
fig_italy = fig_italy.add_annotation(
    dict(
        x = italy_ld_one_month,
        y = 0,
        text = 'Lockdown +1 Month'
    )
)
fig_italy.show()

#####################################################################################################################################
# Now do the same thing for Germany
# Germany started their lockdown on March 23, 2020

germany_ld_start = '2020-03-23'
germany_ld_one_month = '2020-04-23'

# Create a Germany-specific dataframe
df_germany = df[df.Country == 'Germany']
# Cut it down to a local size so it's easier to visualize the impact. Cut-off data after Aug 2020.
df_germany = df_germany[df_germany.Date < '2020-09-01']

df_germany['Daily New Cases'] = df_germany['Confirmed'].diff()
df_germany['Daily New Deaths'] = df_germany['Deaths'].diff()

df_germany['Daily New Cases'] = df_germany['Daily New Cases']/df_germany['Daily New Cases'].max()
df_germany['Daily New Deaths'] = df_germany['Daily New Deaths']/df_germany['Daily New Deaths'].max()

fig_germany = px.line(df_germany, x = 'Date', y = ['Daily New Cases','Daily New Deaths'], title = "Germany COVID19 Infection and Death Rates Around the Lockdown")

fig_germany = fig_germany.add_shape(
    dict(
        type='line',
        x0=germany_ld_start,
        y0=0,
        x1=germany_ld_start,
        y1=df_germany['Daily New Cases'].max(),
        line = dict(color='red',width=2)

    )
)
fig_germany = fig_germany.add_annotation(
    dict(
        x = germany_ld_start,
        y = df_germany['Daily New Cases'].max(),
        text = 'Lockdown Start'
    )
)
fig_germany = fig_germany.add_shape(
    dict(
        type='line',
        x0=germany_ld_one_month,
        y0=0,
        x1=germany_ld_one_month,
        y1=df_germany['Daily New Cases'].max(),
        line = dict(color='orange',width=2)

    )
)
fig_germany = fig_germany.add_annotation(
    dict(
        x = germany_ld_one_month,
        y = 0,
        text = 'Lockdown +1 Month'
    )
)
fig_germany.show()