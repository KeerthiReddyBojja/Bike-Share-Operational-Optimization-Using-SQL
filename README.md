# Bike-Share-Operational-Optimization-Using-SQL

## Business Problem Statement
Citi Bike loses riders and revenue when high-demand stations run out of bikes during morning rush hour. The goal is to use trip data to: 
• Identify where shortages occur
• Detect where bikes accumulate
• Recommend an actionable overnight redistribution strategy

## Data Overview
3 million trips across 2,150 stations from 3 partitions of 23 weekdays in  July 2024 [New York City Citi Bike data](https://s3.amazonaws.com/tripdata/index.html)

## Key Insights (July 2024 data)
**1. Morning Rush Imbalances (6-9 AM):** Top stations depletes an average of 44 bikes per morning.

**2. Evening Surplus Stations (5-8 PM):** Some stations gain 66 bikes/day (5-8 PM), filling docks in the West Village and Financial District.

**3. User Behaviour:** 76.6% of trips are from annual members, confirming predictable weekday patterns.
 annual members, confirming predictable commuter patterns.

**4. Geographic Flow:** 
• Morning deficit stations were concentrated in Midtown and the Financial/Commercial area, indicating these are Job Centers.

• Evening Surplus stations are heavily clustered in Residential and Recreational Hubs, this is where people end their commute or leisure ride.

## Actionable Operational Recommendations 
1. **Overnight Pickup points:** Evening Surplus stations have minimal overnight activity and can be emptied with high confidence.

2. **Pre AM Rush:** Morning deficit stations need stocking between 7-9 AM.

3. Load full load trucks to rebalance bikes between stations and maximize efficiency.

## Tools & Methodology
Tools: PostgreSQL
Validation: The approach mirrors the overnight rebalancing model developed in collaboration with Citi Bike operators.

## Potential Ideas for Further Enhancements
1. Interactive Station Mapping: Use the station's latitude/longitude to plot the deficit and surplus stations on a map. Visualise imbalance spots as pairs and plan for short, efficient distance routes between stations for rebalancing.

2. Enhance the demand models by including dock capacity for each station. 

## References

This project is deeply inspired by and partially implements the rebalancing strategies proposed by the academic research done at Cornell University. This project's approach focuses on mitigating station imbalance, particularly overnight operations. 


[Data Analysis and Optimization for (Citi)Bike Sharing](https://www.researchgate.net/publication/361508513_Data_Analysis_and_Optimization_for_CitiBike_Sharing)













