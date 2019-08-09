-- Recall Routing Addon
-- Austin Smith, University of Maryland Libraries

luanet.load_assembly("System.Data");
local types = {};
types["SqlDbType"] = luanet.import_type("System.Data.SqlDbType");

local Settings = {};
Settings.MaxLoanPeriod = GetSetting("MaxLoanPeriod");
Settings.DaysRemaining = GetSetting("DaysRemaining");
Settings.RecallQueue = GetSetting("RecallQueue");
Settings.RenewalQueue = GetSetting("RenewalQueue");

local isCurrentlyProcessing = false;

function Init()
  LogDebug("Initializing Recall Routing addon.");
	RegisterSystemEventHandler("SystemTimerElapsed", "RecallItems");
end

function RecallItems(eventArgs)
  if isCurrentlyProcessing then return end;
  isCurrentlyProcessing = true;

  -- We're specifically looking for items with short due dates that have not already been recalled.
  local query_template = [[SELECT t.TransactionNumber, t.RenewalsAllowed FROM Transactions AS t LEFT JOIN History AS h ON t.TransactionNumber = h.TransactionNumber
  WHERE t.ProcessType = 'Borrowing' AND t.RequestType = 'Loan'
  AND t.TransactionStatus = 'Checked Out to Customer' AND h.Entry LIKE '% Shipped.'
  AND DATEDIFF(day, h.DateTime, t.DueDate) <= @MaxLoanPeriod
  AND DATEDIFF(day, GETDATE(), t.DueDate) <= 0 - @DaysRemaining
  AND NOT EXISTS(SELECT k.TransactionNumber FROM Tracking AS k WHERE k.TransactionNumber = t.TransactionNumber AND k.ChangedTo = @RecallQueue);]]

  local connection;
  connection = CreateManagedDatabaseConnection();
  connection.QueryString = query_template;
  connection:AddParameter('@MaxLoanPeriod', Settings.MaxLoanPeriod, types.SqlDbType.Int);
  connection:AddParameter('@DaysRemaining', Settings.DaysRemaining, types.SqlDbType.Int);
  connection:AddParameter('@RecallQueue', Settings.RecallQueue, types.SqlDbType.NVarChar);
  LogDebug(connection.QueryString)
  local transactions = connection:Execute();

  ct = transactions.Rows.Count
  LogDebug("Recall Items:"..ct)
  for i = 0, transactions.Rows.Count - 1 do
    local tn = transactions.Rows:get_Item(i):get_Item(0);
    local renewable = transactions.Rows:get_Item(i):get_Item(1);
    LogDebug("Recall Renewable:"..renewable)
    if (renewable == "Yes") then
      ExecuteCommand("Route", {tn, Settings.RenewalQueue});
    else
      ExecuteCommand("Route", {tn, Settings.RecallQueue});
    end
  end

  connection:Dispose();
  isCurrentlyProcessing = false;

end
