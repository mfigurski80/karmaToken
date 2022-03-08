// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract LoanManager {

}

// import "./CollateralManager.sol";

// struct PeriodicLoan {
//     bool failed; // whether service payments were missed
//     address minter; // address that minted this contract
//     uint16 nPeriods; // how many periods until maturity
//     uint16 curPeriod; // current period (how much paid)
//     uint32 periodDuration; // how much time a single period lasts
//     uint64 startTime; // block time this contract was minted
//     uint128 couponSize; // how large a coupon is every period
//     // note: uints add to 256. Efficiency, and realistic limitations
// }

// contract LoanManager {
//     PeriodicLoan[] public loans;
//     CollateralManager private _collateralManager;

//     event LoanCreated(
//         uint256 id,
//         address minter,
//         uint256 amount,
//         uint64 dueDate
//     );
//     event LoanServiced(uint256 id, address servicer, uint256 amount);
//     event LoanCompleted(uint256 id, address servicer);
//     event LoanCalled(uint256 id, address servicer);

//     modifier onlyCreator(uint256 id) {
//         require(
//             loans[id].minter == msg.sender,
//             "LoanManager: Caller must be creator of this loan"
//         );
//         _;
//     }

//     modifier onlyActive(uint256 id) {
//         require(
//             loans[id].nPeriods > loans[id].curPeriod,
//             "LoanManager: Referenced loan must be active"
//         );
//         _;
//     }

//     constructor(address managerAddress) {
//         _collateralManager = CollateralManager(managerAddress);
//     }

//     /**
//      * @dev Allows easy creation of PeriodicLoan from given parameters
//      * @param _nPeriods How many periods should loan last
//      * @param _periodDuration How long a single period is
//      * @param _couponSize How much eth is transfered with one service payment
//      * @return The id of the newly-created PeriodicLoan, i.e it's index in the list
//      */
//     function _createLoan(
//         uint16 _nPeriods,
//         uint32 _periodDuration,
//         uint128 _couponSize
//     ) internal returns (uint256) {
//         uint256 id = loans.length;
//         uint64 nowTime = uint64(block.timestamp);

//         // add loan
//         loans.push(
//             PeriodicLoan(
//                 false,
//                 msg.sender,
//                 _nPeriods,
//                 0,
//                 _periodDuration,
//                 nowTime,
//                 _couponSize
//             )
//         );
//         emit LoanCreated(
//             id,
//             msg.sender,
//             _couponSize * _nPeriods,
//             nowTime + _periodDuration * _nPeriods
//         );
//         return id;
//     }

//     /**
//      * @dev allows you to add an ERC20 Collateral
//      * @param _id ID of loan being referenced
//      * @param _tokenAddress Location of ERC20 contract
//      * @param _count Amount of ERC20 to be held as collateral
//      */
//     function _reserveERC20Collateral(
//         uint256 _id,
//         address _tokenAddress,
//         uint256 _count
//     ) internal {
//         ERC20Collateral memory tok = ERC20Collateral(
//             IERC20(_tokenAddress),
//             _count
//         );
//         _collateralManager.reserveERC20(tok, _id, msg.sender);
//     }

//     /**
//      * @dev allows you to add ERC721 Collateral
//      * @param _id ID of loan being referenced
//      * @param _nftAddress Location of ERC721 contract
//      * @param _nft ID of nft to hold as collateral
//      */
//     function _reserveERC721Collateral(
//         uint256 _id,
//         address _nftAddress,
//         uint256 _nft
//     ) internal {
//         ERC721Collateral memory nft = ERC721Collateral(
//             IERC721(_nftAddress),
//             _nft
//         );
//         _collateralManager.reserveERC721(nft, _id, msg.sender);
//     }

//     /**
//      * @dev Allows user to service their loan with a set amount of ether. Allows
//      *        for overserving, closes the loan if it's completed, and doesn't care
//      *        about lateness of payment. NOTE: eventually, won't transfer payement
//      *        directly, but will instead associate it with the loan for withdrawal
//      * @param _id ID or index of loan you want to service
//      * @param _with Amount of eth the loan has been serviced by
//      * @param _to Address of beneficiary of coupon payments
//      */
//     function _serviceLoan(
//         uint256 _id,
//         uint256 _with,
//         address _to
//     ) internal onlyActive(_id) {
//         // get, check loan
//         PeriodicLoan storage loan = loans[_id];

//         // figure out periods covered by payment
//         uint16 periodsCovered = uint16(_with / loan.couponSize);
//         require(
//             _with >= loan.couponSize,
//             "LoanManager: Payment doesn't meet coupon size"
//         );
//         // perform state changes
//         loan.curPeriod += periodsCovered;
//         // transfer value to beneficiary
//         uint256 acceptedPayment = periodsCovered * loan.couponSize;
//         assert(acceptedPayment <= _with);
//         // payable(_to).transfer(acceptedPayment);
//         (bool success, ) = _to.call{value: acceptedPayment}("");
//         require(success, "LoanManager: failed to accept payment");

//         // emit events
//         emit LoanServiced(_id, msg.sender, acceptedPayment);
//         if (loan.curPeriod > loan.nPeriods) {
//             emit LoanCompleted(_id, msg.sender);
//         }
//     }

//     /**
//      * @dev Cancels the given loan id, performing the required checks
//      * @param _id Id of loan you want to cancel
//      */
//     function _cancelLoan(uint256 _id) internal onlyActive(_id) {
//         loans[_id].curPeriod = loans[_id].nPeriods;
//     }

//     /**
//      * @dev Checks to see if loan payments are overdue, and allows creditor
//      *      access to the collateral if so
//      * @param _id Id of loan you want to check
//      */
//     function _callLoan(uint256 _id) internal onlyActive(_id) {
//         PeriodicLoan storage loan = loans[_id];
//         require(
//             block.timestamp >
//                 loan.startTime + (loan.curPeriod + 1) * loan.periodDuration,
//             "LoanManager: loan contract has not been breached"
//         );
//         loan.failed = true;
//         emit LoanCalled(_id, loan.minter);
//     }

//     // solhint-disable-next-line
//     receive() external payable {}
// }
