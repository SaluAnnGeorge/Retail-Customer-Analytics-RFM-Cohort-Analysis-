import pandas as pd
from sqlalchemy import create_engine

print("🔄 Connecting to database...")

engine = create_engine(
    "mysql+pymysql://root:Database%401234@localhost:3306/superstore_db"
)

# Load data
df = pd.read_sql("SELECT * FROM sales", engine)

print("✅ Data loaded:", df.shape)

# -----------------------
# Data cleaning
# -----------------------
df['Order Date'] = pd.to_datetime(df['Order Date'])
df = df[df['Sales'] > 0]

# -----------------------
# RFM calculation
# -----------------------
today = df['Order Date'].max()

rfm = df.groupby('Customer Name').agg({
    'Order Date': lambda x: (today - x.max()).days,
    'Order ID': 'count',
    'Sales': 'sum'
}).reset_index()

rfm.columns = ['Customer Name', 'Recency', 'Frequency', 'Monetary']

# -----------------------
# RFM scoring
# -----------------------
rfm['R_Score'] = pd.qcut(rfm['Recency'], 5, labels=[5,4,3,2,1])
rfm['F_Score'] = pd.qcut(rfm['Frequency'].rank(method='first'), 5, labels=[1,2,3,4,5])
rfm['M_Score'] = pd.qcut(rfm['Monetary'], 5, labels=[1,2,3,4,5])

rfm['RFM_Score'] = (
    rfm['R_Score'].astype(str) +
    rfm['F_Score'].astype(str) +
    rfm['M_Score'].astype(str)
)

# -----------------------
# Segmentation
# -----------------------
def segment_customer(row):
    if row['RFM_Score'] >= '444':
        return 'Champions'
    elif row['RFM_Score'] >= '344':
        return 'Loyal Customers'
    elif row['RFM_Score'] >= '244':
        return 'Potential Loyalists'
    elif row['RFM_Score'] >= '144':
        return 'At Risk'
    else:
        return 'Hibernating'

rfm['Segment'] = rfm.apply(segment_customer, axis=1)

# -----------------------
# Save output (Week 4)
# -----------------------
rfm.to_csv("rfm_week4_output.csv", index=False)

print("✅ RFM pipeline executed successfully")
print("📁 File saved: rfm_week4_output.csv")






# # Cohort Analysis
# df['Order Month'] = df['Order Date'].dt.to_period('M')

# df['Cohort Month'] = (
#     df.groupby('Customer Name')['Order Date']
#     .transform('min')
#     .dt.to_period('M')
# )

# def cohort_index(df):
#     year_diff = df['Order Month'].dt.year - df['Cohort Month'].dt.year
#     month_diff = df['Order Month'].dt.month - df['Cohort Month'].dt.month
#     return year_diff * 12 + month_diff + 1

# df['Cohort Index'] = cohort_index(df)
# df.to_csv("sales_cohort_week3.csv", index=False)
