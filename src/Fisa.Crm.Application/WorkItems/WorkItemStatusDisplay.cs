namespace Fisa.Crm.Application.WorkItems;

public static class WorkItemStatusDisplay
{
    private static readonly IReadOnlyDictionary<string, string> DisplayStatuses = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
    {
        [WorkItemStatuses.Draft] = "Nháp",
        [WorkItemStatuses.Open] = "Mở",
        [WorkItemStatuses.InProgress] = "Đang xử lý",
        [WorkItemStatuses.WaitingInternal] = "Chờ nội bộ",
        [WorkItemStatuses.WaitingCustomer] = "Chờ khách hàng",
        [WorkItemStatuses.WaitingExternal] = "Chờ đối tác",
        [WorkItemStatuses.Resolved] = "Đã xử lý",
        [WorkItemStatuses.Closed] = "Đã đóng",
        [WorkItemStatuses.Canceled] = "Đã hủy",
        [WorkItemStatuses.Rejected] = "Bị từ chối",
        [WorkItemStatuses.Archived] = "Lưu trữ"
    };

    public static string? GetDisplayStatus(string status)
    {
        return DisplayStatuses.TryGetValue(status, out var label) ? label : null;
    }
}
