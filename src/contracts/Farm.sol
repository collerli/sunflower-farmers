pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "./Token.sol";

contract Farm {
    using SafeMath for uint256;

    Token private token;

    struct Square {
        Fruit fruit;
        uint createdAt;
    }

    mapping(address => Square[]) fields;
    mapping(address => uint) syncedAt;

    constructor(Token _token) public {
        token = _token;
    }

    event FarmCreated(address indexed _address);
    event FarmSynced(address indexed _address);

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    //fallback() external payable {}


    function createFarm(address payable _charity) public payable {
        require(syncedAt[msg.sender] == 0, "FARM_EXISTS");

        uint decimals = token.decimals();

        require(
            msg.value >= 1 * 10**decimals,
            "INSUFFICIENT_DONATION"
        );

        require(
            // The Water Project - double check
            _charity == address(0x060697E9d4EEa886EbeCe57A974Facd53A40865B)
            // Heifer
            || _charity == address(0xD3F81260a44A1df7A7269CF66Abd9c7e4f8CdcD1)
            // Cool Earth
            || _charity == address(0x3c8cB169281196737c493AfFA8F49a9d823bB9c5),
            "INVALID_CHARITY"
        );

        (bool sent, bytes memory data) = _charity.call{value: msg.value}("");
        require(sent, "DONATION_FAILED");


        Square[] storage land = fields[msg.sender];
        Square memory empty = Square({
            fruit: Fruit.None,
            createdAt: block.timestamp
        });
        Square memory apple = Square({
            fruit: Fruit.Apple,
            createdAt: block.timestamp
        });

        // Each farmer starts with 5 fields & 3 apples
        land.push(empty);
        land.push(apple);
        land.push(apple);
        land.push(apple);
        land.push(empty);

        syncedAt[msg.sender] = block.timestamp;

        //Emit an event
        emit FarmCreated(msg.sender);
    }
    
    function lastSyncedAt() private view returns(uint) {
        return syncedAt[msg.sender];
    }


    function getLand() public view returns (Square[] memory) {
        return fields[msg.sender];
    }

    enum Action { Plant, Harvest }
    enum Fruit { None, Apple, Avocado, Banana, Coconut, Pineapple, Money, Diamond }

    struct Event { 
        Action action;
        Fruit fruit;
        uint landIndex;
        uint createdAt;
    }

    struct Farm {
        Square[] land;
        uint balance;
    }

    function getHarvestHours(Fruit _fruit) private pure returns (uint) {
        if (_fruit == Fruit.Apple) {
            return 1;
        } else if (_fruit == Fruit.Avocado) {
            return 3;
        } else if (_fruit == Fruit.Banana) {
            return 8;
        } else if (_fruit == Fruit.Coconut) {
            // 1 Day
            return 24;
        } else if (_fruit == Fruit.Pineapple) {
            // 3 days
            return 72;
        } else if (_fruit == Fruit.Money) {
            // 1 week
            return 168;
        } else if (_fruit == Fruit.Diamond) {
            // 4 weeks
            return 672;
        }

        require(false, "INVALID_FRUIT");
        return 9999999;
    }

    function getSeedPrice(Fruit _fruit) private view returns (uint price) {
        uint decimals = token.decimals();

        if (_fruit == Fruit.Apple) {
            //$0.01
            return 1 * 10**decimals / 100;
        } else if (_fruit == Fruit.Avocado) {
            // $0.06
            return 6 * 10**decimals / 100;
        } else if (_fruit == Fruit.Banana) {
            // $0.20
            return 20 * 10**decimals / 100;
        } else if (_fruit == Fruit.Coconut) {
            // $1
            return 1 * 10**decimals;
        } else if (_fruit == Fruit.Pineapple) {
            // $2
            return 2 * 10**decimals;
        } else if (_fruit == Fruit.Money) {
            // $10
            return 10 * 10**decimals;
        } else if (_fruit == Fruit.Diamond) {
            // $200
            return 200 * 10**decimals;
        }

        require(false, "INVALID_FRUIT");

        return 100000 * 10**decimals;
    }

    function getFruitPrice(Fruit _fruit) private view returns (uint price) {
        uint decimals = token.decimals();

        if (_fruit == Fruit.Apple) {
            // $0.02
            return 2 * 10**decimals / 100;
        } else if (_fruit == Fruit.Avocado) {
            // $0.12
            return 12 * 10**decimals / 100;
        } else if (_fruit == Fruit.Banana) {
            // $0.56
            return 56 * 10**decimals / 100;
        } else if (_fruit == Fruit.Coconut) {
            // $2.30
            return 230 * 10**decimals / 100;
        } else if (_fruit == Fruit.Pineapple) {
            // $6.40
            return 640 * 10**decimals / 100;
        } else if (_fruit == Fruit.Money) {
            // $20
            return 20 * 10**decimals;
        } else if (_fruit == Fruit.Diamond) {
            // $250
            return 250 * 10**decimals;
        }

        require(false, "INVALID_FRUIT");

        return 0;
    }
    
    function requiredLandSize(Fruit _fruit) private pure returns (uint size) {
        if (_fruit == Fruit.Apple || _fruit == Fruit.Avocado) {
            return 5;
        } else if (_fruit == Fruit.Banana || _fruit == Fruit.Coconut) {
            return 8;
        } else if (_fruit == Fruit.Pineapple) {
            return 11;
        } else if (_fruit == Fruit.Money) {
            return 14;
        } else if (_fruit == Fruit.Diamond) {
            return 17;
        }

        require(false, "INVALID_FRUIT");

        return 99;
    }
    
       
    function getLandPrice(uint landSize) private view returns (uint price) {
        uint decimals = token.decimals();
        if (landSize <= 5) {
            // $1
            return 1 * 10**decimals;
        } else if (landSize <= 8) {
            // $30
            return 30 * 10**decimals;
        } else if (landSize <= 11) {
            // $300
            return 300 * 10**decimals;
        }
        
        // $1000
        return 1000 * 10**decimals;
    }

    modifier hasFarm {
        require(lastSyncedAt() > 0, "NO_FARM");
        _;
    }
     
    uint private THIRTY_MINUTES = 30 * 60;

    function buildFarm(Event[] memory _events) private view hasFarm returns (Farm memory currentFarm) {
        Square[] memory land = fields[msg.sender];
        uint balance = token.balanceOf(msg.sender);
        
        for (uint index = 0; index < _events.length; index++) {
            Event memory farmEvent = _events[index];

            uint thirtyMinutesAgo = block.timestamp.sub(THIRTY_MINUTES); 
            require(farmEvent.createdAt >= thirtyMinutesAgo, "EVENT_EXPIRED");
            require(farmEvent.createdAt >= lastSyncedAt(), "EVENT_IN_PAST");
            require(farmEvent.createdAt <= block.timestamp, "EVENT_IN_FUTURE");

            if (index > 0) {
                require(farmEvent.createdAt >= _events[index - 1].createdAt, "INVALID_ORDER");
            }

            if (farmEvent.action == Action.Plant) {
                require(land.length >= requiredLandSize(farmEvent.fruit), "INVALID_LEVEL");
                
                uint price = getSeedPrice(farmEvent.fruit);
                uint fmcPrice = getMarketPrice(price);
                require(balance >= fmcPrice, "INSUFFICIENT_FUNDS");

                balance = balance.sub(fmcPrice);

                Square memory plantedSeed = Square({
                    fruit: farmEvent.fruit,
                    createdAt: farmEvent.createdAt
                });
                land[farmEvent.landIndex] = plantedSeed;
            } else if (farmEvent.action == Action.Harvest) {
                Square memory square = land[farmEvent.landIndex];
                require(square.fruit != Fruit.None, "NO_FRUIT");

                uint duration = farmEvent.createdAt.sub(square.createdAt);
                // Currently seconds
                uint hoursToHarvest = getHarvestHours(square.fruit);
                require(duration >= hoursToHarvest, "NOT_RIPE");

                // Clear the land
                Square memory emptyLand = Square({
                    fruit: Fruit.None,
                    createdAt: 0
                });
                land[farmEvent.landIndex] = emptyLand;

                uint price = getFruitPrice(square.fruit);
                uint fmcPrice = getMarketPrice(price);

                balance = balance.add(fmcPrice);
            }
        }

        return Farm({
            land: land,
            balance: balance
        });
    }


    function sync(Event[] memory _events) public hasFarm returns (Farm memory) {
        Farm memory farm = buildFarm(_events);

        // Update the land
        Square[] storage land = fields[msg.sender];
        for (uint i=0; i < farm.land.length; i += 1) {
            land[i] = farm.land[i];
        }
        
        syncedAt[msg.sender] = block.timestamp;
        
        emit FarmSynced(msg.sender);
        
        uint balance = token.balanceOf(msg.sender);
        // Update the balance - mint or burn
        if (farm.balance > balance) {
            uint profit = farm.balance.sub(balance);
            token.mint(msg.sender, profit);
        } else if (farm.balance < balance) {
            uint loss = balance.sub(farm.balance);
            token.burn(msg.sender, loss);
        }
        

        return farm;
    }

    function levelUp() public hasFarm {
        require(fields[msg.sender].length <= 17, "MAX_LEVEL");

        emit FarmSynced(msg.sender);
        
        Square[] storage land = fields[msg.sender];

        uint price = getLandPrice(land.length);
        uint fmcPrice = getMarketPrice(price);
        uint balance = token.balanceOf(msg.sender);

        require(balance >= fmcPrice, "INSUFFICIENT_FUNDS");
        
        Square memory empty = Square({
            fruit: Fruit.None,
            createdAt: block.timestamp
        });

        // Do not bother rearranging the array - it is already in a strange square - Add 3 fields
        for (uint index = 0; index < 3; index++) {
            land.push(empty);
        }

        token.burn(msg.sender, fmcPrice);

        // Land tax - An additional 5% of profit goes to maintainers of Fruit Market
        uint commission = fmcPrice.div(1);
        token.mint(token.getOwner(), commission);
    }

    // How many FMC do you get per dollar
    // Algorithm is totalSupply / 10000 but we do this in gradual steps to avoid widly flucating prices between plant & harvest
    function getMarketRate() private view returns (uint conversion) {
        uint decimals = token.decimals();
        uint totalSupply = token.totalSupply();

        // Less than 10, 000 FMC tokens
        if (totalSupply < (10000 * 10**decimals)) {
            // 1 Farm Dollar gets you a FMC token
            return 1;
        }

        // Less than 100, 000 FMC tokens
        if (totalSupply < (100000 * 10**decimals)) {
            return 10;
        }
        // Less than 1, 000, 000 FMC tokens
        if (totalSupply < (1000000 * 10**decimals)) {
            return 100;
        }

        // Less than 10, 000, 000 FMC tokens
        if (totalSupply < (10000000 * 10**decimals)) {
            return 1000;
        }

        // Less than 100, 000, 000 FMC tokens
        if (totalSupply < (100000000 * 10**decimals)) {
            return 10000;
        }

        // 200, 000, 000 -> 
        // 1 Farm Dollar gets you a 0.00001 of FMC - Linear growth from here
        return totalSupply.div(10000);
    }

    function getMarketPrice(uint price) public view returns (uint conversion) {
        uint marketRate = getMarketRate();

        return price.div(marketRate);
    }
}