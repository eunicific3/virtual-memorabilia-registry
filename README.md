# Virtual Memorabilia Registry Contract

The **Virtual Memorabilia Registry Contract** is a Clarity smart contract designed for secure cataloging, management, and access control of digital collectible items. This contract enables users to register, modify, reassign, and manage memorabilia items, as well as manage permissions for viewing these items.

## Features

- **Register new memorabilia items**: Users can register items with a label, dimensions, and categories.
- **Modify item details**: Update labels, dimensions, categories, and additional metadata.
- **Reassign ownership**: Transfer item ownership to a new registrant.
- **Permission management**: Grant or revoke viewer access for specific items.
- **Access control**: Secure item access through permission-based viewing.
- **Error handling**: Comprehensive error handling for invalid operations.

## Contract Functions

### Public Functions:
- **register-item**: Register a new item with metadata (label, dimensions, memo, categories).
- **reassign-item**: Transfer item ownership to a new registrant.
- **modify-item-details**: Update item details such as label, dimensions, memo, and categories.
- **remove-item**: Delete an item from the registry.
- **grant-viewer-access**: Grant viewing permission to another user.
- **revoke-viewer-access**: Revoke viewing permission from a user.

### Query Functions:
- **has-viewer-access**: Check if a user has permission to view an item.
- **get-registry-count**: Retrieve the total number of registered items.

## Error Codes

- **u301**: Item not found in registry.
- **u302**: Item already exists.
- **u303**: Invalid label format.
- **u304**: Dimensions out of bounds.
- **u305**: User lacks required permission.
- **u307**: Admin restricted action.
- **u308**: Permission denied.

## Setup Instructions

### Requirements:
- [Clarity language compiler](https://claritylang.org/)
- [Blockstack CLI](https://github.com/blockstack/blockstack-cli) (for deploying the contract)

### Installation:

1. Clone the repository:
    ```bash
    git clone https://github.com/yourusername/virtual-memorabilia-registry.git
    cd virtual-memorabilia-registry
    ```

2. Install the required dependencies (if applicable):
    ```bash
    npm install
    ```

3. Deploy the contract to your desired Clarity-supported blockchain.

### Testing:

Run the unit tests to ensure the contract functions correctly:

```bash
clarity test
```

## Usage

To interact with the contract, use the following functions:

1. **Register a new item**:  
    `register-item` with item details (label, dimensions, memo, and categories).

2. **Modify an item**:  
    `modify-item-details` with the item serial and updated details.

3. **Reassign ownership**:  
    `reassign-item` to transfer ownership.

4. **Manage permissions**:  
    `grant-viewer-access` and `revoke-viewer-access` to manage who can view items.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
