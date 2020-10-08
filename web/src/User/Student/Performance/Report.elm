module User.Student.Performance.Report exposing (PerformanceReport, emptyPerformanceReport)


type alias PerformanceReport =
    { html : String
    }


emptyPerformanceReport : PerformanceReport
emptyPerformanceReport =
    { html = "<div>No results found.</div>"
    }
