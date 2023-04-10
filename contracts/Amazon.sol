// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Amazon {
    struct Product {
        string name;
        string description;
        uint price;
        uint stock;
        address payable seller;
        address payable buyer;
        bool isDelivered;
    }

    mapping(uint => Product) public product;
    mapping(uint => mapping(address => uint)) public amountOfPurchasedProducts;
    uint productId = 1;
    uint checkReentrancy = 1;

    function listProduct(
        string memory _name,
        string memory _description,
        uint _price,
        uint _stock
    ) public {
        require(_price >= 0, "Price should be greater than zero!");
        Product memory newProduct;

        newProduct.name = _name;
        newProduct.description = _description;
        newProduct.price = _price * 1 ether;
        newProduct.stock = _stock;
        newProduct.seller = payable(msg.sender);

        product[productId] = newProduct;
        productId++;
    }

    function buyProduct(uint id, uint quantity) public payable {
        Product storage selectedProduct = product[id];
        require(selectedProduct.price != 0, "Product does not exist");
        require(selectedProduct.stock > 0, "Product is out of stock");
        require(
            selectedProduct.seller != msg.sender,
            "Seller can not buy product"
        );
        require(
            msg.value == selectedProduct.price * quantity,
            "You do not have enough ether"
        );

        selectedProduct.stock -= quantity;
        selectedProduct.buyer = payable(msg.sender);
        if (amountOfPurchasedProducts[id][msg.sender] == 0) {
            amountOfPurchasedProducts[id][msg.sender] = quantity;
        } else {
            amountOfPurchasedProducts[id][msg.sender] += quantity;
        }
    }

    function delivered(uint id) public {
        require(checkReentrancy == 1);
        checkReentrancy = 2;
        Product memory purchasedProduct = product[id];
        require(
            purchasedProduct.buyer == msg.sender,
            "You are not the buyer!!"
        );
        uint quantity = amountOfPurchasedProducts[id][msg.sender];

        payable(purchasedProduct.seller).transfer(
            purchasedProduct.price * quantity
        );
        checkReentrancy = 1;
    }
}
