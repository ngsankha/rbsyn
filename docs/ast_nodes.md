# Extension to AST Nodes

The `ast` library's Node class has been extended into a `TypedNode`, so each node now carries around type information. The type of each node is available from the `ttype` accessor method.

Apart from that there are extensions to the kind of nodes that are used:

* `hole`
* `filled_hole`
* `envref`

Note that these are not part of the real Ruby AST, hence these can be imagined as something abstract that can be used to carry around information for the synthesis process. Any AST with these nodes present cannot be serialized into Ruby source.