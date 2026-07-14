# Data Architecture

All application data is scoped by the authenticated Firebase user:

```txt
users/{uid}
  customers/{customerId}
  customerCnpjs/{cnpjDigits}
  products/{productId}
  nfc/{nfcId}
  nfcReturns/{returnId}
```

## Customers

```txt
name: string
cnpj: string
cnpjDigits: string
createdAt: timestamp
updatedAt: timestamp
```

## Customer CNPJ Index

```txt
customerId: string
createdAt: timestamp
updatedAt: timestamp
```

`customerCnpjs/{cnpjDigits}` enforces unique customer CNPJ values per user.
Different users can still register the same CNPJ because the index is scoped
under `users/{uid}`.

## Products

```txt
name: string
pricePerKg: string
createdAt: timestamp
updatedAt: timestamp
```

`pricePerKg` is stored as a Brazilian decimal string with comma separator and
two decimal places, for example `12,50`.

## NFC

```txt
code: string
date: string
products: ProductSnapshot[]
customerId: string
totalValue: string
createdAt: timestamp
updatedAt: timestamp
```

`totalValue` is the invoice value. It follows the same Brazilian decimal string
format used by product prices, for example `1500,00`.

`products` stores snapshots of the selected products, including:

```txt
productId: string
name: string
pricePerKg: string
quantityKg: string
```

## NFC Returns

```txt
code: string
date: string
products: ProductSnapshot[]
nfcId: string
nfcCode: string
createdAt: timestamp
updatedAt: timestamp
```

`NFC` and `NFC Returns` store small snapshots of related records. This keeps
old records readable even if the original customer or product is renamed later.
Customer relation stays live through `customerId`.

`NFCReturn.products` must be copied from the related `NFC.products`, not from
the current product documents.
