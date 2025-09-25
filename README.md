# DigitalDistricts Smart Contract

A decentralized virtual commercial zone built on the Stacks blockchain for hosting virtual offices, coworking spaces, and business meetings.

## 🌟 Overview

DigitalDistricts is a Clarity smart contract that enables users to create, rent, and manage virtual commercial spaces in a trustless, decentralized manner. The platform facilitates peer-to-peer transactions for virtual office rentals with automatic payments and reputation tracking.

## ✨ Features

### 🏢 Space Management
- **Create Virtual Spaces**: Set up offices, coworking spaces, or meeting rooms
- **Flexible Pricing**: Set hourly rates in STX
- **Capacity Control**: Define maximum occupancy for each space
- **Amenities Listing**: Describe available features and services
- **Active Status Toggle**: Enable/disable spaces as needed

### 📅 Booking System
- **Time-based Reservations**: Book spaces for specific time periods
- **Automatic Payments**: Seamless STX transfers with platform fees
- **Booking Management**: View and cancel reservations
- **Availability Checking**: Real-time space availability verification

### 👤 User Profiles
- **Professional Profiles**: Company information and contact details
- **Reputation System**: Track booking history and user reliability
- **Booking Statistics**: Monitor total reservations and activity

### 💰 Payment Processing
- **Direct STX Payments**: Secure blockchain-based transactions
- **Platform Fee Collection**: Configurable commission structure (default 5%)
- **Instant Settlements**: Immediate payment to space owners

## 🛠 Installation & Deployment

### Prerequisites
- Stacks CLI or Clarinet for deployment
- STX tokens for transactions
- Access to Stacks testnet/mainnet

### Deployment Steps

1. **Clone/Download the contract**
```bash
# Save the contract as digital-districts.clar
```

2. **Deploy using Clarinet**
```bash
clarinet deploy --testnet digital-districts
```

3. **Deploy using Stacks CLI**
```bash
stx deploy_contract digital-districts digital-districts.clar --testnet
```

## 📖 Usage Guide

### For Space Owners

#### 1. Create a Virtual Space
```clarity
(contract-call? .digital-districts create-space
  "office"                    ;; space-type
  "Modern Office Suite"       ;; name
  "Fully equipped office..."  ;; description
  u100                       ;; price-per-hour (100 microSTX)
  u10                        ;; max-capacity
  "WiFi, Printer, Coffee"    ;; amenities
)
```

#### 2. Update Space Details
```clarity
(contract-call? .digital-districts update-space
  u1                         ;; space-id
  "Updated Office Name"      ;; name
  "New description..."       ;; description
  u120                       ;; new-price-per-hour
  u15                        ;; new-max-capacity
  "WiFi, Printer, Snacks"    ;; updated-amenities
)
```

#### 3. Toggle Space Status
```clarity
(contract-call? .digital-districts toggle-space-status u1)
```

### For Renters

#### 1. Create User Profile
```clarity
(contract-call? .digital-districts update-profile
  "John Smith"               ;; name
  "Tech Solutions Inc"       ;; company
)
```

#### 2. Book a Space
```clarity
(contract-call? .digital-districts book-space
  u1                         ;; space-id
  u1640995200               ;; start-time (Unix timestamp)
  u1641002400               ;; end-time (Unix timestamp)
)
```

#### 3. Cancel Booking
```clarity
(contract-call? .digital-districts cancel-booking u1) ;; booking-id
```

### Query Functions

#### Get Space Information
```clarity
(contract-call? .digital-districts get-space u1)
```

#### Get Booking Details
```clarity
(contract-call? .digital-districts get-booking u1)
```

#### Check User Profile
```clarity
(contract-call? .digital-districts get-user-profile 'SP1234...)
```

#### Check Space Availability
```clarity
(contract-call? .digital-districts is-space-available 
  u1                         ;; space-id
  u1640995200               ;; start-time
  u1641002400               ;; end-time
)
```

## 🔧 Data Structures

### Space Object
```clarity
{
  owner: principal,
  space-type: (string-ascii 20),    ;; "office", "coworking", "meeting"
  name: (string-ascii 50),
  description: (string-ascii 200),
  price-per-hour: uint,
  max-capacity: uint,
  is-active: bool,
  amenities: (string-ascii 100)
}
```

### Booking Object
```clarity
{
  space-id: uint,
  renter: principal,
  start-time: uint,              ;; Unix timestamp
  end-time: uint,                ;; Unix timestamp
  total-cost: uint,
  is-active: bool
}
```

### User Profile Object
```clarity
{
  name: (string-ascii 50),
  company: (string-ascii 50),
  reputation-score: uint,
  total-bookings: uint
}
```

## ⚡ Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | `err-owner-only` | Action requires contract owner privileges |
| u101 | `err-not-found` | Requested resource not found |
| u102 | `err-already-exists` | Resource already exists |
| u103 | `err-insufficient-payment` | Insufficient STX balance |
| u104 | `err-not-authorized` | User not authorized for this action |
| u105 | `err-space-occupied` | Space is already booked |
| u106 | `err-invalid-fee` | Platform fee exceeds maximum (20%) |

## 🔐 Security Features

- **Access Control**: Function-level authorization checks
- **Payment Validation**: Automatic balance verification
- **Input Sanitization**: Proper type checking and constraints
- **Owner Protection**: Secure space ownership verification
- **Anti-fraud**: Booking conflict prevention

## 💡 Smart Contract Architecture

### Constants
- Immutable error codes for consistent error handling
- Contract owner identification

### Data Variables
- `next-space-id`: Auto-incrementing space identifier
- `next-booking-id`: Auto-incrementing booking identifier
- `platform-fee-percentage`: Configurable commission rate

### Maps
- `spaces`: Storage for all virtual space data
- `bookings`: Reservation and transaction records
- `user-profiles`: User information and reputation tracking

## 🚀 Advanced Features

### Platform Administration
Only contract owner can:
- Update platform fee percentage (max 20%)
- Modify system-wide settings

### Time-based Pricing
- Hourly rate calculation
- Automatic duration computation
- Pro-rated billing support

### Reputation System
- Booking count tracking
- User reliability scoring
- Trust-building mechanisms

## 🧪 Testing

### Test Cases to Implement
1. **Space Creation**: Verify successful space creation and ID assignment
2. **Booking Flow**: Test complete booking process with payments
3. **Authorization**: Confirm access control mechanisms
4. **Edge Cases**: Handle insufficient funds, invalid times, etc.
5. **Admin Functions**: Test platform fee updates and permissions

### Example Test Commands
```bash
# Using Clarinet
clarinet test

# Manual testing with Stacks CLI
stx call_read_only_contract_func ...
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Submit a pull request

## 📄 License

This project is open-source. Please check the license file for details.

## 🔗 Resources

- [Stacks Documentation](https://docs.stacks.co/)
- [Clarity Language Reference](https://docs.stacks.co/clarity/)
- [Clarinet Documentation](https://github.com/hirosystems/clarinet)

---

**Built with ❤️ on Stacks Blockchain**