# Data Architecture

All application data is scoped by the authenticated Firebase user:

```txt
users/{uid}
  customers/{customerId}
  products/{productId}
  nfc/{nfcId}
  nfcReturns/{returnId}
```

## Customers

```txt
name: string
cnpj: string
createdAt: timestamp
updatedAt: timestamp
```

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
