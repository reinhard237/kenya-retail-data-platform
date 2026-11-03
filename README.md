# Kenya Retail Analytics Project

## 1. Project Overview

The Kenya Retail Analytics Project is an end-to-end data analytics project designed to examine retail business performance and generate insights that can support data-informed decision-making. The project uses synthetic retail data to investigate sales performance, customer purchasing behaviour, product and store performance, promotional activities, product returns, and customer churn risk.

The project combines Python, SQL, PostgreSQL, and Microsoft Power BI to demonstrate a complete data analytics workflow, from data generation and preparation to database development, statistical analysis, and interactive business intelligence reporting.

Python is used for data preparation, cleaning, feature engineering, and statistical analysis. PostgreSQL provides the database environment for storing and querying structured retail data, while SQL is used to create analytical views and support reporting. Microsoft Power BI is used to present the results through interactive dashboards and key performance indicators.

The project is intended to demonstrate the practical application of data analytics tools and techniques within a retail business context, using synthetic data rather than actual business or customer records.

## 2. Project Objectives

The main objectives of this project are to:

- Generate and prepare synthetic retail datasets for analytical purposes.
- Develop a repeatable data cleaning and transformation pipeline.
- Identify and address missing values, incorrect data types, duplicate records, and outliers.
- Perform exploratory and statistical analysis of retail transactions.
- Examine sales performance and trends over time.
- Evaluate product, category, and store performance.
- Analyze customer purchasing behaviour, loyalty, and payment preferences.
- Examine promotional activities, discounts, and product returns.
- Develop customer churn scores using relevant customer purchasing features.
- Store and query structured retail data using PostgreSQL.
- Develop an interactive Power BI dashboard to communicate analytical findings.
- Demonstrate an integrated workflow involving Python, SQL, PostgreSQL, and Power BI.

## 3. Technologies and Tools

The project uses the following technologies and tools.

| Technology | Purpose |
|---|---|
| Python | Data preparation, cleaning, transformation, and analysis |
| Pandas | Data manipulation and preparation |
| NumPy | Numerical operations |
| Matplotlib | Data visualization |
| Seaborn | Statistical data visualization |
| Scikit-learn | Machine learning and predictive analysis |
| SciPy | Statistical analysis |
| Statsmodels | Statistical modelling |
| Jupyter Notebook | Interactive analysis and documentation |
| PostgreSQL | Relational database management |
| Aiven | Hosted PostgreSQL database service |
| DBeaver | Database management and SQL execution |
| SQL | Data querying, aggregation, indexing, and analytical views |
| Microsoft Power BI | Interactive dashboards and business intelligence reporting |
| Git | Version control |
| GitHub | Source code management and project documentation |

## 4. Repository Structure

The project repository is organized into the following directories and files.

```text
capstone-project/
│
├── Notebook/
│   └── statistical_analysis.ipynb
│
├── data/
│   ├── clean/
│   │   └── customer_churn_scores.csv
│   │
│   ├── raw/
│   │
│   └── generate_data.py
│
├── reports/
│   └── kenya retail.pbix
│
├── sql/
│   └── script.sql
│
├── .gitignore
└── README.md
```

### Directory and File Descriptions

**Notebook/**

Contains the Jupyter Notebook used for data preparation, statistical analysis, exploratory data analysis, and analytical exploration.

- `statistical_analysis.ipynb` contains the Python-based analytical workflow.

**data/**

Contains the datasets and data generation script used in the project.

- `raw/` contains the original datasets used as inputs for data preparation and analysis.
- `clean/` contains cleaned or generated analytical outputs.
- `generate_data.py` contains the Python script used to generate synthetic retail data.

**reports/**

Contains the completed Power BI dashboard.

- `kenya retail.pbix` is the interactive Power BI report developed for retail performance analysis.

**sql/**

Contains the SQL scripts used for database development and reporting.

- `script.sql` contains SQL statements for database operations, indexing, and the creation of analytical views.

**.gitignore**

Specifies files and directories that should not be tracked by Git, including local environment files and other excluded project files.

**README.md**

Provides the main project documentation, including the project overview, objectives, tools, methodology, outputs, and instructions for reproducing the analysis.

## 5. Data Generation and Preparation

The project uses synthetic retail data to simulate a retail business environment. This allows the development and testing of analytical processes without relying on actual customer or business records.

The `generate_data.py` script supports the generation of synthetic datasets used in the project. The generated data provides the foundation for subsequent cleaning, transformation, database development, and analysis.

Data preparation is performed using Python, primarily through the Pandas and NumPy libraries.

The preparation workflow addresses the following areas:

### 5.1 Data Type Correction

Examining dataset columns and ensuring that variables are represented using appropriate data types. This includes dates, numerical variables, and categorical fields.

### 5.2 Missing Value Treatment

Identifying missing observations and applying appropriate treatment based on the characteristics and analytical purpose of the affected variables.

### 5.3 Duplicate Detection and Removal

Identifying duplicate records and handling them appropriately to reduce the possibility of double-counting and inaccurate analysis.

### 5.4 Outlier Examination

Examining unusual numerical observations and assessing their potential influence on analytical results. Appropriate treatment is applied where necessary.

### 5.5 Feature Engineering

Creating additional variables from existing data to support further analysis. These features help examine sales performance, customer purchasing patterns, and customer churn risk.

### 5.6 Data Validation

Reviewing the prepared datasets to assess data consistency, completeness, and suitability for subsequent analytical activities.

The data preparation process is designed to be repeatable, allowing the workflow to be rerun from the original datasets when required.

## 6. Exploratory and Statistical Analysis

The project uses descriptive statistics, exploratory data analysis, and other analytical techniques to examine the characteristics and patterns within the synthetic retail datasets.

The analysis covers several business areas.

### 6.1 Sales Analysis

Examines overall retail sales performance using measures such as:

- Total sales
- Net sales
- Gross profit
- Total invoices
- Units sold
- Average invoice value
- Monthly sales performance

### 6.2 Product and Category Analysis

Examines the contribution of individual products and product categories to retail performance. This includes sales comparisons, units sold, and gross profit.

### 6.3 Store Performance Analysis

Evaluates differences in retail performance across stores and locations. The analysis considers sales, profitability, transaction volumes, and geographical distribution.

### 6.4 Customer Behaviour Analysis

Examines customer purchasing patterns and engagement through variables such as:

- Purchase frequency
- Recency of purchases
- Monetary contribution
- Repeat purchasing behaviour
- Loyalty membership
- Payment preferences
- Sales channels

### 6.5 Promotion and Returns Analysis

Examines promotional performance, discount patterns, and returned products. This helps assess the contribution of promotional activities and identify patterns in product returns.

### 6.6 Customer Churn Analysis

The project includes a customer churn scoring output generated using customer purchasing information.

The file `data/clean/customer_churn_scores.csv` contains the following variables:

| Variable | Description |
|---|---|
| `customer_id` | Synthetic customer identifier |
| `snapshot` | Reference date associated with the customer score |
| `recency_days` | Number of days since the customer's most recent purchase |
| `freq_all` | Customer purchase frequency |
| `monetary_all` | Customer monetary contribution |
| `churn_probability` | Estimated probability of customer churn |
| `risk_band` | Customer churn-risk category |

These variables support the examination of customer inactivity and the classification of customers according to their estimated churn risk.

The churn probabilities should be interpreted as model-based analytical estimates within the synthetic dataset rather than verified predictions of actual customer behaviour.

## 7. Database Development and SQL Analysis

PostgreSQL is used as the relational database management system for the project. The database is hosted through Aiven, while DBeaver is used to manage database objects and execute SQL statements.

The database component supports the organization, querying, and aggregation of retail transaction data.

Key database activities include:

- Connecting to the PostgreSQL database.
- Working with structured retail tables.
- Executing SQL queries to retrieve and aggregate transaction data.
- Creating indexes on frequently queried fields.
- Developing analytical views for Power BI reporting.

### 7.1 Database Indexing

Indexes were created on selected transaction fields to support query performance.

The indexed fields include:

- `transaction_date`
- `store_id`
- `product_id`
- `customer_id`
- `invoice_no`
- `promo_id`

### 7.2 Analytical SQL Views

The SQL script creates eight analytical views to support reporting and dashboard development.

| View | Purpose |
|---|---|
| `vw_dash_sales_overview` | Summarizes overall retail sales and business performance |
| `vw_dash_sales_trends` | Provides monthly sales information for trend analysis |
| `vw_dash_product_performance` | Supports product and category performance analysis |
| `vw_dash_store_performance` | Summarizes store-level performance |
| `vw_dash_customer_analysis` | Provides customer purchasing and behavioural information |
| `vw_dash_payment_analysis` | Supports payment method and sales channel analysis |
| `vw_dash_promotion_analysis` | Summarizes promotional activities and discount performance |
| `vw_dash_returns_analysis` | Supports analysis of returned products and return performance |

These views organize the underlying transaction data into reporting structures that simplify the development of Power BI visualizations and analytical measures.

## 8. Power BI Dashboard and Reporting

Microsoft Power BI is used to develop an interactive, multi-page dashboard that presents the main findings of the retail analytics project.

The dashboard combines key performance indicators, charts, tables, and interactive filters to support the examination of retail business performance.

It contains five main analytical pages.

### 8.1 Executive Overview

Provides a high-level summary of retail performance.

Key measures and visualizations include:

- Total net sales
- Gross profit
- Total invoices
- Net units sold
- Monthly sales trends
- Top-performing stores
- Sales by product category

### 8.2 Sales Trends and Seasonality

Examines changes in retail sales over time.

The page includes:

- Monthly net sales trends
- Month-over-month sales growth
- Year-over-year sales growth
- Average monthly sales
- Best-performing sales months

These measures support the identification of sales patterns and changes in performance across the reporting period.

### 8.3 Product and Store Performance

Examines how individual products, product categories, and retail locations contribute to business performance.

The page includes:

- Sales by product category
- Top-performing products
- Units sold
- Gross profit
- Store-level sales comparisons
- Sales by county
- Store performance by store type

### 8.4 Customer Behaviour

Examines customer purchasing patterns, loyalty, and payment preferences.

The page includes:

- Identified customers
- Average spend per customer
- Repeat customer percentage
- Loyalty membership share
- Customer distribution by age group
- Payment method preferences
- Sales channel distribution
- Customer purchasing patterns

### 8.5 Promotions and Returns

Examines promotional activities, discount performance, and returned products.

The page includes:

- Number of promotions
- Promotional sales
- Total discounts
- Effective discount percentage
- Returned sales value
- Product return rates
- Promotional performance comparisons
- Return patterns across products and locations

The report also incorporates interactive navigation and filters to make it easier to explore different areas of the retail business.

## 9. Reproducing the Project

The following instructions provide a general guide for setting up the project environment and reproducing the analytical workflow.

### 9.1 Clone the Repository

Clone the GitHub repository to your local machine.

```bash
git clone <YOUR_GITHUB_REPOSITORY_URL>
cd capstone-project
```

Replace `<YOUR_GITHUB_REPOSITORY_URL>` with the actual repository URL.

### 9.2 Create a Python Virtual Environment

Create a virtual environment in the project directory.

```bash
python -m venv venv
```

Activate it using Windows PowerShell.

```powershell
.\venv\Scripts\Activate.ps1
```

### 9.3 Install the Required Python Packages

Install the libraries used in the project.

```bash
python -m pip install pandas numpy matplotlib seaborn scikit-learn scipy statsmodels jupyter sqlalchemy psycopg2-binary python-dotenv ipykernel
```

Register the environment as a Jupyter kernel if necessary.

```bash
python -m ipykernel install --user --name capstone-venv --display-name "Python (capstone-venv)"
```

### 9.4 Generate or Load the Data

Review `data/generate_data.py` and execute the data generation process if you need to recreate the synthetic datasets.

The original datasets should be placed in the appropriate `data/raw/` directory, while prepared analytical outputs should be stored in `data/clean/`.

### 9.5 Run the Python Notebook

Open:

`Notebook/statistical_analysis.ipynb`

in VS Code or Jupyter Notebook.

Select the project's Python virtual environment as the notebook kernel and execute the notebook cells in their intended order.

Ensure that the required input datasets are available before running the analysis.

### 9.6 Configure the PostgreSQL Database

The project uses PostgreSQL hosted through Aiven.

To reproduce the database component:

1. Set up an accessible PostgreSQL database.
2. Configure the connection using your own database credentials.
3. Load the required retail datasets into the database.
4. Open `sql/script.sql` using DBeaver or another PostgreSQL-compatible SQL client.
5. Execute the SQL statements to create the required indexes and analytical views.

Database credentials should be stored securely using environment variables or a local `.env` file. Never commit database passwords or other sensitive credentials to GitHub.

### 9.7 Open the Power BI Dashboard

Open the following file using Microsoft Power BI Desktop:

`reports/kenya retail.pbix`

If using a different database connection, update the data source settings and credentials before refreshing the report.

## 10. Key Project Deliverables

The repository includes the following main deliverables.

| Deliverable | Location | Description |
|---|---|---|
| Synthetic data generation script | `data/generate_data.py` | Generates synthetic retail datasets |
| Raw datasets | `data/raw/` | Contains original input datasets |
| Cleaned analytical outputs | `data/clean/` | Contains prepared datasets and analytical outputs |
| Statistical analysis | `Notebook/statistical_analysis.ipynb` | Python-based data preparation and analysis |
| SQL implementation | `sql/script.sql` | Database operations, indexing, and analytical views |
| Customer churn scores | `data/clean/customer_churn_scores.csv` | Synthetic customer-level churn scoring output |
| Power BI dashboard | `reports/kenya retail.pbix` | Interactive retail analytics report |
| Project documentation | `README.md` | Project overview, methodology, and reproduction instructions |

## 11. Limitations and Considerations

The project uses synthetic data, and its findings should therefore be interpreted within the context of the simulated retail environment.

The main considerations include:

- The results are intended for analytical demonstration and should not be treated as direct evidence of actual Kenyan retail market conditions.
- Customer churn probabilities depend on the assumptions and methods used to generate the scores.
- Analytical findings depend on the completeness, consistency, and structure of the underlying datasets.
- Reproducing the database component requires access to the relevant PostgreSQL database and valid connection credentials.
- Power BI data refresh depends on the availability of the configured data source.
- Measures and visualizations should be interpreted according to their definitions and the aggregation level of the underlying analytical views.

## 12. Future Improvements

Potential extensions to the project include:

- Comparing different machine learning models for customer churn prediction.
- Evaluating predictive performance using appropriate classification metrics.
- Developing more advanced customer segmentation techniques.
- Automating data preparation and database refresh processes.
- Introducing scheduled dashboard updates.
- Expanding the analysis to include inventory management and demand forecasting.
- Developing additional analytical models to support retail decision-making.

## 13. Conclusion

The Kenya Retail Analytics Project demonstrates an integrated approach to retail data analytics by combining data generation, data preparation, statistical analysis, database development, and interactive business intelligence reporting.

Through the use of Python, PostgreSQL, SQL, and Microsoft Power BI, the project illustrates how synthetic retail data can be transformed into structured analytical outputs and meaningful business reports.

The resulting workflow provides a foundation for examining sales performance, understanding customer behaviour, evaluating promotional activities, and exploring customer churn risk. It also demonstrates the practical application of data analytics tools and techniques in a simulated retail business environment.

---

**Project Name:** Kenya Retail Analytics Project

**Data Type:** Synthetic Retail Data

**Primary Technologies:** Python, PostgreSQL, SQL, and Microsoft Power BI

**Version Control:** Git and GitHub