# CompanyCustomerSupport.ps1
Write-Host("`n")
Write-Host "=> _____ CompanyCustomerSupport ___________ <=`n" 

class CompanyCustomerSupport {
    [System.Collections.ArrayList]$SupportTickets

    CompanyCustomerSupport() {
        $this.SupportTickets = [System.Collections.ArrayList]@()
    }

    [void] AddSupportTicket([string]$ticketID, [string]$customer, [string]$issue, [string]$status) {
        $ticket = [PSCustomObject]@{
            ID = $ticketID
            Customer = $customer
            Issue = $issue
            Status = $status
            AssignedStaff = $null
        }
        $this.SupportTickets.Add($ticket)
        Write-Host "Support ticket added: ID=$ticketID, Customer=$customer, Issue=$issue, Status=$status"
    }

    [void] AssignTicketToStaff([string]$ticketID, [string]$staffName) {
        $ticket = $this.SupportTickets | Where-Object { $_.ID -eq $ticketID }
        if ($ticket) {
            $staff = [PSCustomObject]@{ Name = $staffName }
            $ticket.AssignedStaff = $staff
            Write-Host "Ticket $ticketID assigned to $staffName"
        } else {
            Write-Host "Ticket $ticketID not found."
        }
    }

    [void] UpdateTicketStatus([string]$ticketID, [string]$newStatus) {
        $ticket = $this.SupportTickets | Where-Object { $_.ID -eq $ticketID }
        if ($ticket) {
            $ticket.Status = $newStatus
            Write-Host "Updated status of ticket $ticketID to $newStatus"
        } else {
            Write-Host "Ticket $ticketID not found."
        }
    }

    [void] ListSupportTickets() {
        Write-Host "Support Tickets:"
        foreach ($ticket in $this.SupportTickets) {
            Write-Host "Ticket ID: $($ticket.ID), Customer: $($ticket.Customer), Issue: $($ticket.Issue), Status: $($ticket.Status)"
            if ($ticket.AssignedStaff -ne $null) {
                Write-Host "Ticket $($ticket.ID) assigned to $($ticket.AssignedStaff.Name)."
            }
        }
    }
}






