xquery version "1.0-ml";

declare namespace ml = "http://developer.marklogic.com/site/internal";

declare variable $PAGE-SIZE := 10;

xdmp:set-response-content-type("application/json"),

let $tags as xs:string* := fn:tokenize(xdmp:get-request-field("tags"), ";;")

let $page := try { xs:int(xdmp:get-request-field("p", "1")) } catch ($e) { 1 }
let $start := ($page - 1) * $PAGE-SIZE + 1
let $end := $start + $PAGE-SIZE - 1
let $query :=
  cts:and-query((
    cts:directory-query("/recipe/", "infinity"),
    if (fn:exists($tags)) then
      cts:and-query((
        $tags ! cts:element-value-query(xs:QName("ml:tag"), .)
      ))
    else()
  ))
let $total := xdmp:estimate(cts:search(fn:doc(), $query))
let $results :=
  cts:search(
    fn:doc(),
    $query
  )[$start to $end]
return object-node {
  "total": $total,
  "pages": fn:ceiling($total div $PAGE-SIZE),
  "start": $start,
  "end": $end,
  "recipes": array-node {
    for $recipe in $results
    return
      object-node {
        "title": fn:normalize-space($recipe/ml:Recipe/ml:title/fn:string()),
        "url": fn:replace(fn:base-uri($recipe), ".xml", ""),
        "problem": fn:normalize-space($recipe/ml:Recipe/ml:problem/fn:string()),
        "minVersion": fn:normalize-space($recipe/ml:Recipe/ml:min-server-version/fn:string()),
        "maxVersion": fn:normalize-space($recipe/ml:Recipe/ml:max-server-version/fn:string()),
        "tags": array-node {
          $recipe/ml:Recipe/ml:tags/ml:tag/fn:string()
        }
      }
  }
}
