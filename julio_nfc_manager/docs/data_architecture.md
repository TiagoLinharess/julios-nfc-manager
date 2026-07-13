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
amountKg: string
createdAt: timestamp
updatedAt: timestamp
```

## NFC

```txt
code: string
date: string
products: ProductSnapshot[]
customerId: string
amount: int
createdAt: timestamp
updatedAt: timestamp
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
