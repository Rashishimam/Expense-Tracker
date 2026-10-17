# 💎 AuraSpend — Full-Stack Expense & Finance Tracker

A production-grade, full-stack personal finance and expense tracking application architected with a decoupled **React + Vite** frontend client and a **Node.js + Express + SQLite** RESTful backend API.

![Architecture](https://img.shields.io/badge/Architecture-Decoupled_Client_/_Server-6366f1)
![Database](https://img.shields.io/badge/Database-SQLite_Persistent-10b981)
![Frontend](https://img.shields.io/badge/Frontend-React_18_+_Vite-f43f5e)
![Backend](https://img.shields.io/badge/Backend-Express_+_Node.js-38bdf8)

---

## 📑 Table of Contents
1. [Project Overview & Key Highlights](#-project-overview--key-highlights)
2. [Folder Architecture](#-folder-architecture)
3. [Database Model & Schema](#-database-model--schema)
4. [RESTful API Specification](#-restful-api-specification)
5. [Dual-Layer Validation Architecture](#-dual-layer-validation-architecture)
6. [Quick Start & Setup Guide](#-quick-start--setup-guide)
7. [Automated Verification Suite](#-automated-verification-suite)

---

## 🌟 Project Overview & Key Highlights

- **Decoupled Architecture**: Strict separation of concerns between client UI and backend REST service.
- **Persistent Database**: SQLite storage with WAL (Write-Ahead Logging) and automatic seed data. Records persist across server restarts.
- **Mathematical Accuracy**: All financial totals, net savings, and category aggregates are calculated in database queries, ensuring 100% parity between frontend balance cards and database records.
- **Dynamic Balance Cards**: Live metrics for Total Income, Total Expenses, Current Net Savings, and Ledger Activity with savings rate indicators.
- **Interactive Transaction Ledger**:
  - Filterable by Transaction Type (`income` / `expense`), Category, and Keyword Search.
  - Sorter by Date, Amount, and Category.
  - Category badges with distinct color-coding.
  - Edit and Delete capabilities with confirmation dialogs.
- **Dual-Layer Validation**:
  - **Client-Side**: Instant visual feedback, red borders, and inline error messages before network requests.
  - **Server-Side**: Strict request validation rejecting invalid amounts (≤ 0, non-numeric, overflow) or invalid dates (non-calendar dates like Feb 31st) independently of the client UI.
- **Premium Aesthetics**: Dark glassmorphism theme, smooth animations, responsive flex/grid layouts, and modern typography (`Plus Jakarta Sans` and `JetBrains Mono`).

---

## 📁 Folder Architecture

```text
Expense Tracker/
├── client/                     # Frontend SPA (React + Vite)
│   ├── public/
│   ├── src/
│   │   ├── components/
│   │   │   ├── BalanceCards.jsx        # Dynamic financial balance cards
│   │   │   ├── CategoryBreakdown.jsx   # Expenditure distribution & progress bars
│   │   │   ├── DeleteModal.jsx         # Delete confirmation modal
│   │   │   ├── FilterBar.jsx           # Search, type, category, and sorting filters
│   │   │   ├── Header.jsx              # Brand header, server status, currency switcher
│   │   │   ├── Icons.jsx               # Vector SVG icons
│   │   │   ├── Toast.jsx               # Animated toast notifications
│   │   │   ├── TransactionList.jsx     # Responsive transaction ledger table
│   │   │   └── TransactionModal.jsx    # Add / Edit modal with dual validation
│   │   ├── services/
│   │   │   └── api.js                  # Centralized REST API client
│   │   ├── App.jsx                     # Root application state & synchronization
│   │   ├── index.css                   # Bespoke Vanilla CSS design system
│   │   └── main.jsx
│   ├── index.html
│   ├── package.json
│   └── vite.config.js                  # Vite server & backend proxy configuration
│
├── server/                     # Backend REST API Server (Node.js + Express)
│   ├── controllers/
│   │   └── expenseController.js        # CRUD controllers & mathematical summary
│   ├── db/
│   │   ├── database.js                 # SQLite connection & seed initialization
│   │   └── schema.sql                  # Database DDL & index definitions
│   ├── middleware/
│   │   ├── errorHandler.js             # Global error handler & 404 router
│   │   └── validator.js                # Strict server-side request validator
│   ├── routes/
│   │   └── expenses.js                 # Express REST route endpoints
│   ├── .env.example
│   ├── .env
│   ├── package.json
│   ├── server.js                       # Express application entry point
│   ├── test-api.js                     # Automated API verification test runner
│   └── expenses.sqlite                 # Persistent SQLite database file
│
├── package.json                # Root workspace configuration
├── start.bat                   # One-click Windows startup script
└── README.md                   # Complete architectural documentation
```

---

## 🗄️ Database Model & Schema

The persistent SQLite database schema is defined in [`server/db/schema.sql`](file:///server/db/schema.sql):

```sql
CREATE TABLE IF NOT EXISTS expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category TEXT NOT NULL,
  amount REAL NOT NULL CHECK(amount > 0),
  date TEXT NOT NULL,
  description TEXT NOT NULL,
  type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date DESC);
CREATE INDEX IF NOT EXISTS idx_expenses_type ON expenses(type);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category);
```

### Field Definitions

| Field | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` | Unique identifier for each transaction |
| `category` | `TEXT` | `NOT NULL` | Category name (e.g., Salary, Housing, Groceries) |
| `amount` | `REAL` | `NOT NULL`, `CHECK(amount > 0)` | Monetary figure (strictly positive, 2 decimals) |
| `date` | `TEXT` | `NOT NULL` | Calendar date in strict `YYYY-MM-DD` ISO format |
| `description` | `TEXT` | `NOT NULL`, `1..255 chars` | Description of the transaction |
| `type` | `TEXT` | `CHECK(type IN ('income', 'expense'))` | Transaction flow classification |
| `created_at` | `TEXT` | `DEFAULT datetime('now')` | Creation timestamp |
| `updated_at` | `TEXT` | `DEFAULT datetime('now')` | Last modification timestamp |

---

## 📡 RESTful API Specification

Base URL: `http://localhost:5000/api`

### Endpoints Overview

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/api/health` | Health check endpoint returning server status & uptime |
| `GET` | `/api/expenses/summary` | Aggregated mathematical balance totals & category breakdowns |
| `GET` | `/api/expenses` | Retrieve filtered transaction list |
| `GET` | `/api/expenses/:id` | Retrieve single transaction by ID |
| `POST` | `/api/expenses` | Create new transaction (runs server-side validation) |
| `PUT` | `/api/expenses/:id` | Update existing transaction (runs server-side validation) |
| `DELETE`| `/api/expenses/:id` | Delete transaction from persistent database |

---

### Detailed Endpoints

#### 1. Retrieve Summary (`GET /api/expenses/summary`)
Calculates mathematical totals directly in SQLite:
```json
{
  "success": true,
  "summary": {
    "totalIncome": 6420.00,
    "totalExpenses": 2241.60,
    "netSavings": 4178.40,
    "savingsRate": 65.1,
    "totalTransactions": 10,
    "incomeTransactions": 3,
    "expenseTransactions": 7,
    "categoryBreakdown": [
      { "category": "Salary", "type": "income", "totalAmount": 4850.00, "count": 1 },
      { "category": "Housing", "type": "expense", "totalAmount": 1650.00, "count": 1 }
    ],
    "monthlyTrends": [
      { "month": "2026-10", "income": 6420.00, "expense": 2241.60 }
    ]
  }
}
```

#### 2. List Transactions (`GET /api/expenses`)
Supported Query Parameters:
- `type`: `income` | `expense`
- `category`: Category name string
- `search`: Keyword matching description or category
- `startDate`: Start date (`YYYY-MM-DD`)
- `endDate`: End date (`YYYY-MM-DD`)
- `sortBy`: `date` | `amount` | `category`
- `order`: `DESC` | `ASC`

Response:
```json
{
  "success": true,
  "count": 1,
  "data": [
    {
      "id": 1,
      "category": "Salary",
      "amount": 4850.00,
      "date": "2026-10-05",
      "description": "Tech Lead Monthly Salary",
      "type": "income",
      "created_at": "2026-10-17 08:49:53",
      "updated_at": "2026-10-17 08:49:53"
    }
  ]
}
```

#### 3. Create Transaction (`POST /api/expenses`)
Request Body:
```json
{
  "category": "Groceries",
  "amount": 84.50,
  "date": "2026-10-16",
  "description": "Weekly organic vegetables",
  "type": "expense"
}
```

Response (`201 Created`):
```json
{
  "success": true,
  "message": "Transaction recorded successfully.",
  "data": {
    "id": 11,
    "category": "Groceries",
    "amount": 84.50,
    "date": "2026-10-16",
    "description": "Weekly organic vegetables",
    "type": "expense",
    "created_at": "2026-10-17 08:50:00",
    "updated_at": "2026-10-17 08:50:00"
  }
}
```

---

## 🛡️ Dual-Layer Validation Architecture

The application enforces validation at both the user interface and the API boundary:

```text
User Input
    │
    ▼
[ Layer 1: Client-Side Validation ]
    ├── Amount > 0 and numeric
    ├── Valid Date format (YYYY-MM-DD)
    ├── Non-empty Category & Description (≤ 255 chars)
    └── Displays inline field error text & red focus borders
    │
    ▼ (HTTP POST / PUT Request)
[ Layer 2: Server-Side Validator Middleware ]
    ├── Independent rejection of malicious or bypassed client inputs
    ├── Type safety: strictly 'income' or 'expense'
    ├── Real calendar date verification (rejects leap year issues, e.g. Feb 31st)
    ├── Boundary limits (Amount ≤ 1,000,000,000)
    └── Returns HTTP 400 with structured JSON errors:
```

Example Rejection Response (`400 Bad Request`):
```json
{
  "success": false,
  "error": "Validation failed",
  "errors": [
    { "field": "amount", "message": "Amount must be strictly greater than 0." },
    { "field": "date", "message": "Invalid date format. Expected valid calendar date in YYYY-MM-DD format." }
  ]
}
```

---

## 🚀 Quick Start & Setup Guide

### Prerequisites
- [Node.js](https://nodejs.org/) v18.0.0 or higher
- [npm](https://www.npmjs.com/) v9.0.0 or higher

### 1. One-Click Start (Windows)
Double-click `start.bat` in the project root. This launches both the backend API and frontend Vite server in separate terminal windows.

### 2. Manual Setup via Terminal

#### Step 1: Install Dependencies
```bash
# In the project root:
npm run setup

# Or manually:
cd server && npm install
cd ../client && npm install
```

#### Step 2: Start Backend Server
```bash
cd server
npm start
# Server listens at: http://localhost:5000
```

#### Step 3: Start Frontend Client
```bash
cd client
npm run dev
# Frontend runs at: http://localhost:5173
```

Open `http://localhost:5173` in any modern web browser.

---

## 🧪 Automated Verification Suite

Run the built-in automated test suite to verify all backend REST endpoints, SQLite persistence, and validation rules:

```bash
cd server
node test-api.js
```

Or from the workspace root:
```bash
npm run test:api
```

Test Results Output:
- Health check: `PASS`
- Summary financial metrics & aggregation: `PASS`
- GetAll listing: `PASS`
- Server-side validation rejection of negative amounts & invalid calendar dates: `PASS`
- Server-side rejection of invalid transaction type: `PASS`
- Create valid transaction: `PASS`
- Update transaction: `PASS`
- Delete transaction: `PASS`
