module Student.Performance.Report exposing (..)


type alias PerformanceReport =
    { html : String, pdf_link : String }


emptyPerformanceReport : PerformanceReport
emptyPerformanceReport =
    { html = "<div>No results found.</div>", pdf_link = "" }
