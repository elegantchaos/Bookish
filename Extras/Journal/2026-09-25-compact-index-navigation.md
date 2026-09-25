# Compact Index Navigation

Selecting a browser index on compact iOS went directly to a record detail. The navigation service cleared the old record on index change, then selected the first record as soon as the new query result arrived.

Explicit index selection now clears the record selection before refreshing the query. This applies when selecting the current index and when moving between indexes with commands. The record list remains visible until a record is selected. Startup's existing default selection and record creation's explicit selection remain intact.

A navigation regression test covers index selection, repeated selection, query refresh, and explicit record selection. Existing navigation command tests now check that moving between indexes leaves no record selected.
