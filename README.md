# ILLiadRecallRoutingAddon

##Context

The NCIP implementation in use at the University of Maryland College Park has certain limitations:

1. All items must have the same fixed loan period
2. No patron-initiated renewals are possible.

This addon was developed to help us strike a balance between serving our patrons and not abusing our lenders, but letting us quickly identify which items need to be renewed or recalled.

## Description

Checks items in the *Checked Out to Customer* queue. Based on loan period and proximity of due date, routes them to a queue for renewal if renewals are allowed, or to a queue for recall if renewals are not allowed.

Once an item has been routed to the recall queue, it will not be routed there again (to avoid infinite loops). An item can be routed to the renewal queue multiple times, so renewals can be requested repeatedly, so long as the "Allow Renewals" box is checked.

## Settings

MaxLoanPeriod - Only items with loan periods less than or equal to this number of days will be recalled.

DaysRemaining - Number of days, relative to due date, at which the request will be recalled. If negative, request will be recalled before the due date.

RecallQueue - Queue to which non-renewable items will be routed.

RenewalQueue - Queue to which renewable items will be routed.
