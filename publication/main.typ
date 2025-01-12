#import "ilm.typ": *
#import "@preview/xarrow:0.3.0": xarrow, xarrowSquiggly, xarrowTwoHead
#import "@preview/equate:0.2.1": equate

// for definition and example subheadings
#import "@preview/great-theorems:0.1.1": *
#import "@preview/rich-counters:0.2.2": *

// for listings
#import "@preview/codly:1.1.1": *
#show: codly-init.with()
#codly(languages: (
  HTML: (
    name: "SPARQL", color: green
  )
))

// for ER-Diagrams
#import "@preview/pintorita:0.1.3"

#set text(lang: "en", region: "GB")
#show: great-theorems-init
#show raw.where(lang: "pintora"): it => pintorita.render(it.text) // todo: Add this back in when I want to print.

#let spct = sym.space.punct
#show "e.g.": [e.#sym.space.thin\g.] // unsure whether I like this.
#show "i.e.": [i.#sym.space.thin\e.]
#show "B.Sc.": [B.#spct\Sc.]
#show "M.Sc.": [M.#spct\Sc.]
#show "Prof. Dr.": [Prof.#spct\Dr.]

#let assessor = [Prof. Dr. Clemens Beckstein\ M. Sc. Johannes Mitschunas]
#let degree = [Bachelor of Science (B. Sc.)]

#show: ilm.with(
  title: [Query by Graph],
  author: "Friedrich Answin Daniel Motz",

  // cover-german: (
  //   faculty: "Fakultät für Mathematik und Informatik",
  //   university: "Friedrich-Schiller-Universität Jena",
  //   type-of-work: "Bachelorarbeit",
  //   academic-degree: degree,
  //   field-of-study: "Informatik",
  //   author-info: "15. Juli 2001 in Chemnitz, Deutschland",
  //   assessor: assessor,
  //   place-and-submission-date: "Jena, 12. Januar 2025",
  // ),

  cover-english: (
    faculty: "Faculty for Mathematics and Computer Science",
    university: "Friedrich Schiller University Jena",
    type-of-work: "Bachelor Thesis",
    academic-degree: degree,
    field-of-study: "Computer Science",
    author-info: "15 July 2001 in Chemnitz, Germany",
    assessor: assessor,
    place-and-submission-date: "Jena, 12 January 2025",
  ),
  
  abstract: [
    This thesis establishes the foundation for a visual query builder for SPARQL queries, called *Query by Graph*. The developed program enables users to construct queries for Wikibase instances without the need for coding. Since RDF triplestore contents can be represented as graphs, queries can too. With Query by Graph, users can visually sketch the desired graph structure and insert variables to retrieve results. Additionally, Query by Graph introduces an intuitive representation for querying special Wikibase constructs directly, enhancing usability and functionality.
  ],
  
  preface: align(left)[
    This bachelor thesis represents the culmination of a journey fuelled by my commitment to making complex things more accessible. Along the way, I have been fortunate to receive invaluable support, guidance, and inspiration from several remarkable individuals.  

    First and foremost, I owe the genesis of this work to Olaf Simons. His blog post and the initiative FactGrid sparked my interest in exploring Visual Query Graphs and Wikibase, laying the foundation for this thesis.  

    I am deeply grateful to Lucas Werkmeister, whose expertise in the technical intricacies of Wikibase was indispensable. His guidance helped me navigate complexities I could not have overcome alone.  

    Special thanks go to Patrick Stahl for his contributions to implementing UI features. Your technical skills enriched the practical aspects of this work. 

    This program owes its early public exposure to Clemens Beck. Thank you for testing it in your seminar and for providing crucial support and manpower to accelerate its development.

    My deepest gratitude, however, goes to Clemens Beckstein and Johannes Mitschunas for their exceptional mentorship. Their wisdom, encouragement, and thoughtful feedback were instrumental in shaping this project and pushing it to its full potential.  

    Each of you has played a vital role in bringing this thesis to fruition. Your support has made this journey not only intellectually rewarding but also personally meaningful.

    To all of you, I extend my heartfelt gratitude.  
  ],
  
  appendix: [
    #set heading(outlined: false)
    #heading(numbering: none, "Use of Generative AI")
    This bachelor thesis was written in assistance of the OpenAI large language models GPT-4o and GPT-o1 preview. The large language models were used to ease literature research and to point out stylistic, orthographical and grammatical mistakes to the writer.
  ],
  
  abbreviations: (
    ("W3C", "World Wide Web Consortium (registered trademark)"),
    ("RDF", "Resource Description Framework"),
    ("RDFS", "Resource Description Framework Schema (Ontology within RDF)"),
    ("SPARQL", [SPARQL Protocol And RDF Query Language (see @heading:sparql)]),
    ("IRI", [Internationalised Resource Identifier (see @heading:iri)]),
    ("BGP", [Basic Graph Pattern (@def:bgp)]),
    ("OWL", "Web Ontology Language"),
    ("VQG", [Visual Query Graph (see @def:vqg)]),
    ("VQL", "Visual Query Language"),
    ("WASM", [Web Assembly]),
    ("API", "Application Programming Interface"),
    ("WWW", "World Wide Web")
  ),

  external-link-circle: true, // TURN THIS OFF IF YOU GENERATE THE PRINT VARIANT
  
  figure-index: (enabled: true),
  table-index: (enabled: true),
  listing-index: (enabled: true),
  bibliography: bibliography(title: "Bibliography", style: "ieee", "bib.yaml")
)

/* BEGIN Custom Environment */

#let mathcounter = rich-counter(
  identifier: "mathblocks",
  inherited_levels: 1
)

#let definition = mathblock(
  blocktitle: "Definition",
  counter: mathcounter
)

#let theorem = mathblock(
  blocktitle: "Theorem",
  counter: mathcounter,
)

#let lemma = mathblock(
  blocktitle: "Lemma",
  counter: mathcounter,
)

#let example = mathblock(
  blocktitle: "Example",
  counter: mathcounter,
)

#let remark = mathblock(
  blocktitle: "Remark",
  prefix: [_Remark._],
  // inset: 5pt,
  // fill: lime,
  // radius: 5pt,
)

#let proof = proofblock()

#let note(it) = text(fill: luma(150), size: 0.7em, it)
#let spruch(it) = move(dx: -30pt, text(style: "italic", fill: luma(100), quote(it)))

#let longArrow = xarrow.with(
  sym: sym.arrow.long,
  width: 5em,
  partial_repeats: false,
)

#show: equate.with(breakable: true, sub-numbering: true)
#set math.equation(numbering: "(A.1)", supplement: "Eq.")

#set heading(numbering: "1.1")
#set quote(block: true)

#show heading.where(level: 1): it=> [#v(.5cm) #it #v(.2cm)]
#show heading.where(level: 2): it=> [#v(.5cm) #it #v(.2cm)]

#show raw: set text(
  font: "Noto Sans Mono",
  weight: 300,
  ligatures: true,
  discretionary-ligatures: true,
  historical-ligatures: true,
)

/* END Custom Environment */

= Introduction <heading:introduction>

Over its thousands of years in existence, humanity has built an _infrastructure for knowledge_. It started out with stone tablets, evolved to hand-written papyrus books, libraries, the printing press and recently culminated in computer and the internet. Instead of using a library and asking a librarian, we usually consult "the internet" using a search engine -- even for small questions. Now, in order to answer a question, the search engine needs to be able to treat the contents of a website in a semantically correct way, just like a human would. This is achieved using i.e. network analysis and techniques of natural language processing. However, what if the contents of websites could be semantically annotated by their creators?

This question lead to the inception of the Wikidata#footnote[https://www.wikidata.org] initiative, among others. Their idea is to rewrite Wikipedia articles into very simple assertions using a specified vocabulary. These assertions consist of a subject, predicate and an object, in analogy to sentence structures in linguistics, where subjects and objects can refer to objects of our intuition and predicates define how they are related. These assertions are also referred to as *triples*. Another benefit of these triples is their ability to be represented as a graph (see @fig:rdf_graph_fragment), where nodes represent subjects and objects (or e.g. Wikipedia articles), and edges represent predicates, also called properties or relationships. This triple structure allows to easily visualise the database's entries.

#let lalalalalala = 90pt
$
  "Goethe (subject)"& xarrow("educated at (predicate)", width: lalalalalala)& "Leipzig (object)" \
  "Goethe"& xarrow("place of birth", width: lalalalalala) &"Frankfurt am Main"
$

#figure(
  caption: [A graphical visualisation of the triple $("Goethe", "educated at", "Leipzig")$ as a graph. Subjects and objects are represented as nodes and predicates are represented as edges between these nodes.],
  image("example_triple_graph.svg", width: 230pt)
) <fig:rdf_graph_fragment>

Wikidata contains a very big set of such triples, posing the opportunity, that it could be used like a database and queried for information, just like classical relational databases. Such databases can be implemented using a framework called Resource Description Framework (RDF) and are called *triplestore* or *RDF graph*. A resource can be any object of our intuition and these resources can be described using the syntax RDF offers. The vocabulary used to describe the resources, is specified or chosen by the users. Triplestores can be advantageous when the information collected is incomplete or might be enhanced later on. In contrast, any entry in a relational database needs to be consistent with the specified data model and applications making use of that data in turn expect consistency. By design, an application using triplestores must account for the absence of data.

The maximally flexible data model is what lead triplestores to become popular in the digital humanities. An initiative called FactGrid#footnote[https://factgrid.de] hosts a triplestore specifically designed for historians, enabling them to make the data from their research publicly accessible. This poses the potential, that a user with knowledge of the specified vocabulary and conventions of the database, could get information about historical facts by writing an adequate query to the database. Furthermore, inferencing information about historical facts could be made a matter of, again, writing an adequate query.

== Problem
Making use of a triplestore in a broader audience poses the challenge, that the technicalities of the database are exposed to its user. To populate and query the database, the users have to attend to the conventions of the vocabulary and the database engineers. The formalisation step is therefore being put into the hands of e.g. historians. Secondly, to adequately query a database, the user is forced to use the query language _SPARQL_, which requires technical knowledge.

#figure(caption: [The process of getting a result from an RDF triplestore.],
  image("methodology_pipeline_without_proposal.svg", width: 100%)
)

For example, a researcher might ask: "What professions did members of societies dedicated to advancements in the natural sciences in Jena hold?" There are many ways to interpret this question: Does the question refer to registered clubs, meaning a legal entity or does a regular's table in a pub count? What does the term profession refer to? Is it the current _occupation_ or the _trained_ profession? Secondly, before starting to write a SPARQL query, the next step is to 'pre-formalise' the question using the concise 'subject, predicate, object' syntax, to adequately captures the interpretation's essence. This requires familiarity with the database's modelling conventions. For example, a researcher could query for entities classified as clubs and ensure that these entities are also associated with 'natural sciences' through the predicate 'interested in'. Alternatively, things related to 'Natural research association' through the predicate 'instance of' could be queried. Both options seem just, but in practice, only _one_ returns results.

However, these initiatives want to reach a broader user base than the one likely to engage given these hurdles. It is unreasonable to expect users to navigate these steps without substantial training, a clear understanding of typical modelling practices, and in-depth knowledge of SPARQL language features.

#figure(caption: [A possible SPARQL query to the professions of members of societies for natural sciences in Jena from the database FactGrid.],
```HTML
PREFIX fg: <https://database.factgrid.de/entity/>
PREFIX fgt: <https://database.factgrid.de/prop/direct/>
SELECT DISTINCT ?careerStatement WHERE {
  ?society fgt:P2 fg:Q266832 .
  ?society fgt:P83 fg:Q10391 .
  ?people fgt:P91 ?society .
  ?people fgt:P165 ?careerStatement .
}
```) <fig:example_query_introduction>

== Proposal
This work aims to lay the fundamentals for a program, which allows to build queries to an RDF triplestore using visual representation. The idea is, that since the _contents_ of the RDF triplestore can be _visualised as a graph_, _so could the query_ @Vargas2019_RDF_Explorer @Simons_Blog_Entry_Graphic_query. Instead of writing a query in the database's query language SPARQL, the user employs a visual query builder, which in turn generates the equivalent query.

Creating a Visual Query Graph is similar to sketching: the user outlines the desired database structure and fills in variables for the desired results. The sketched graph is then automatically converted into a SPARQL query that adheres to all syntactical requirements. A result is retrieved from an RDF triplestore by finding the same graph structure as specified by the query. A variable will match any value.

#figure(caption: [Methodology pipeline: How to get from a question in natural language to the result  in an RDF database.],
  image("methodology_pipeline.svg", width: 100%)
)

This work aims to closely integrate with the triplestore software suite called Wikibase#footnote[https://wikiba.se], which is widely adopted#footnote[e.g. Wikidata and FactGrid]. Wikibase offers many very useful constructs, which, by their nature, require some technicalities to be represented using the triple syntax, e.g. further specifications of a property (which in Wikibase are called qualifiers). This work demonstrates that, beyond the standard triple syntax, such complex constructs can be represented as intuitive structures and queried using a Visual Query Graph, following @Simons_Blog_Entry_Graphic_query. To achieve this, it introduces the conventions of data modelling in Wikibase and explains their mapping to RDF syntax.

#figure(
  caption: [A screenshot of the Visual Query Graph which generates the above posted query. Variables are shown in violet and things in light blue. Green nodes show which variables are part of the result set.],
  image("screenshot_quebyg_example.png")
) <fig:screenshot_example_vqg>

#figure(
  caption: [An exemplary RDF Graph against which query from @fig:example_query_introduction is run.],
  image("RDF_Graph_example.svg"),
)

The results of typical SPARQL queries on an RDF graph are presented as a table, with each column representing a requested variable. For this example, the table will have one column which includes all career statements associated with Goethe and Böber ${"Author", "Head of State", "Director", "Explorer", "Professor"}$.

Query by Graph cannot fully eliminate the need for users to learn the conventions of an RDF triplestore. For instance, determining which subjects are available and what to expect is entirely dependent on the database's users and engineers, as is the naming of properties. However, with Query by Graph, querying an RDF graph becomes as simple as drawing a suitable stencil that mirrors the RDF graph's structure. The desired pattern is sketched, while any undefined elements are left as variables to be resolved during the query process. Using the editor's search fields, users can quickly adjust the meanings of nodes and edges, creating a workflow that feels more intuitive and similar to sketching a chain of thought. 

@heading:preliminaries provides the necessary preliminaries, including the fundamentals of RDF, SPARQL, and the data model used in Wikibase. @heading:querying delves into the principles of querying RDF graphs and the specific challenges posed by Wikibase's advanced constructs. @heading:mapping introduces the concept of Visual Query Graphs and how they are mapped to SPARQL queries. It furthermore discusses the implementation of the tool *Query by Graph*, which incorporates and realises a significant portion of the features conceptualised in this thesis. @heading:discussion discusses the implications, limitations, and potential extensions of the proposed approach.


= Preliminaries <heading:preliminaries>
To define the tasks of Query by Graph, it is essential to discuss Wikibase's data modelling conventions, the formal definitions of Wikibase's special constructs, their mapping to the Resource Description Framework (RDF), the RDF itself and the syntax of the query language for RDF, SPARQL. The most commonly used SPARQL queries for retrieving information are SPARQL-SELECT queries, which are the primary focus of this work. SPARQL-SELECT queries function like stencils that describe a triple pattern, which is applied across an RDF graph until a matching pattern is found. For each match in the RDF graph, the corresponding variable assignments are returned as a result set. The idea is that the Visual Query Graph will represent the same stencil as the SPARQL-SELECT query.

Certain patterns in the RDF graph of Wikibase exist solely for technical reasons and are not intuitive to users without an understanding of the underlying necessities. For example, this includes relationships involving multiple objects. These patterns are limited in scope and are defined within the Wikibase data model, providing an opportunity to develop an intuitive representation for them in the Visual Query Graph. During query generation from the Visual Query Graph, these intuitive representations are translated into technically accurate constructs, ensuring they can be queried successfully.

== Resource Description Framework
To introduce the Wikibase data model and its mapping to the Resource Description Framework (RDF), it is essential to first understand the terminology of RDF.

=== Internationalised Resource Identifier <heading:iri>

Internationalised Resource Identifiers (IRIs) [#link("https://www.ietf.org/rfc/rfc3987.txt")[RFC3987]] are a superset of Uniform Resource Identifiers (URIs) [#link("https://www.ietf.org/rfc/rfc3986.txt")[RFC3986]], for example `http://database.factgrid.de/entity/Q409` and `https://database.factgrid.de/prop/direct/P160`. Their purpose is to unambiguously *refer to a resource* across all triplestores (or the WWW). The resource an IRI points at is called *referent* @W3C_RDF_1.1_Reference.


#remark[IRIs can largely be treated as URIs, as they are interchangeable through conversion. Their primary purpose is to *identify the entity being referenced within a specific triplestore or Wikibase instance*. Since the technical details are not directly relevant to this work, I will refer readers to the referenced RFCs for further information.]


=== Prefixing <def:prefixes_and_bases>
RDF allows to define a *prefix*, which acts as an *abbreviation of an IRI*. For example, let `wd` be a prefix with the value `http://www.wikidata.org/entity/`. Then, the IRI `http://www.wikidata.org/entity/Q5879` can be rewritten using this prefix as `wd:Q5879`. The part after the colon is called *local name* and is essentially a string restricted to alphanumerical characters @W3C_RDF_1.1_Reference. The term "prefix" will also be used to describe specific prefixes in the Wikibase data model: Each Wikibase instance defines a set of prefixes and data modelling conventions around them.

=== Literals <heading:literals>

A *literal* in an RDF graph can be used to express values such as strings, dates and numbers. It essentially consists of two elements#footnote[The specifications and the new proposal for RDF allow for more elements for language-tagging @W3C_RDF_1.1_Reference @W3C_RDF_1.2_Proposal, however, they are not relevant to this work.]:
+ a *lexical form*, which is a Unicode string,
+ a *data type IRI*, which defines the mapping from the lexical form to the literal value in the user representation.

=== Blank nodes
RDF specifies *blank nodes*, which do not have an IRI nor a literal assigned to them. The specification @W3C_RDF_1.1_Reference and the current version of its successor @W3C_RDF_1.2_Proposal do not comment on the structure of a blank node: "Otherwise, the set of possible blank nodes is arbitrary." @W3C_RDF_1.1_Reference.
It only specifies, that *the set of blank nodes is disjunct from all literals and IRIs*. In most common RDF formats, a blank node can be locally referenced using a *local name* and a special "empty" IRI-prefix often denoted by an underscore character.

=== RDF Triple and RDF Graph <heading:triples>

To establish a concise notation for subsequent definitions, this work introduces specific sets to be used throughout. The set of all IRIs is represented by *$I$*, the set of all blank nodes by *$B$*, and the set of literals by *$L$*. The set of all valid RDF terms is defined as *$T := I union L union B$*.

#definition[
  Let
  $bold("s") in bold("I") union bold("B")$ be a subject,
  $bold("p") in bold("I")$ a predicate and
  $bold("o") in bold("T")$ an object.

  Then, following @W3C_RDF_1.1_Reference, an *RDF triple* or simply a *triple*, is defined as
  $
    (bold("s"), bold("p"), bold("o")).
  $
] <def:spo>

#definition[An *RDF graph* is a set of RDF triples. An RDF triple is said to be asserted in an RDF graph if it is an element of the RDF graph @W3C_RDF_1.2_Proposal.] <def:rdf_graph>

== Data Model in Wikibase
*Wikibase* is one of the most widely used softwares for community knowledge bases, with the most prominent instance, *Wikidata*#footnote[http://wikidata.org --- an initiative for a free community knowledge base], storing \~115 million data items. Wikibase has its own internal structure and conventions for naming and modelling entities and concepts. These internals are in turn mapped to an expression in RDF syntax @wikibase_rdf_mapping_article. This invertible mapping permits the use of _RDF terminology to refer to structures within Wikibase_ and most notably _the use of the SPARQL query language for information retrieval_. This specific data model of Wikibase is particularly noteworthy due to its widespread use and substantial influence on other initiatives, driven by its sheer scale. For example, DBpedia will make use of Wikidata resources @Lehmann2015DBpediaA.

In Wikibase, a *thing* is referred to as an *item* and assigned a unique *Q-Number* within a Wikibase instance. Any *predicate* is called *property* and assigned a unique *P-Number*. A statement in Wikibase puts an item in relation to another item using a property.


#let lala2 = lalalalalala/2

#example[
  Suppose a user wants to enhance an entry in Wikidata for a person called "Johann Wolfgang von Goethe". Goethe is modelled as an item with the Q-number `Q5879` and wants to add the statement, that Goethe was "educated at" (P-number `P69`) the "University of Leipzig" (Q-number `Q154804`). Using the user interface, the user edits the entry for Goethe and fills the fields "property" and "object" with `P69` and `Q154804`.
  The triple representation in an RDF graph would be very similar:
  $
    "Johann Wolfgang von Goethe" &xarrow("educated at",width:lala2) "University of Leipzig", quad "or" \
    "Q5879" &xarrow("P69", width:lala2) "Q154804."
  $ <ex_spo_goethe>
]

Most real-world relationships might present to be more complex than something one would want to model in a single triple. For example, one may want to express that "Goethe" was educated at the "University of Leipzig" from 3 October 1765 to 28 August 1768. Wikibase represents it as a hierarchical structure, with "educated at" as the primary property and the others arranged beneath it. In the Wikibase context, a statement specifying another relationship is called a *qualifier*.

#figure(
  caption: [Presentation of an qualified relationship in the software Wikibase.],
  image("screenshot_wikidata.png", width: 320pt)
)<fig:qualifier_screenshot>

// TODO: bei diesem Beispiel jurisprudence rausnehmen.

One possibility is to let relationships have more than two operands, i.e. increase the arity by one for each additional parameter. "Educated at" would then be called "educated at (#sym.dot) from (#sym.dot) to (#sym.dot)". Another way using the triple syntax is to create an implicit object, that assists in modelling the relationship using an *implicit* or *blank node* to describe a new concept; a human might be inclined to give it a name, e.g. "educated at for a certain time". This act is also called *reification* (objectification of a fact).
The following triples exemplify such an implicit relationship, called a *qualified statement*:
$
  "Goethe" &longArrow("educated at") && "Uni Leipzig", \
  "Goethe" &longArrow("educated at") && "Implicit1", \
  "Implicit1" &longArrow("location") && "Uni Leipzig", \
  "Implicit1" &longArrow("started at") && 3.10.1765, #<ex_qualifier_1> \
  "Implicit1" &longArrow("ended at") && 28.08.1768.  #<ex_qualifier_2>
$ <ex:assertions_goethe_education>

The statements of @ex_qualifier_1 and @ex_qualifier_2 are called *qualifiers*.

#figure(image("Qualifier_ohne.svg", width: 320pt), caption: [Graphical visualisation of a qualified statement using natural language descriptors.]) <fig:vqg_no_qualifier>

Wikibase instances define IRI-prefixes for things of the same kind. This allows to think of them as namespaces for categories defined within the Wikibase data model. Since this work treats the set of all possible Wikibase instances where the IRIs use different domain names from e.g. `wikidata.org`, they can be thought of as variables for the instance-specific prefix. For convenience, these variables will be denoted by the prefix names followed by a colon (`wd:`, `p:`, `pq:`, `wdt:` and so on) defined by Wikidata (see @example:prefixes_in_wikidata). For the matters of this work, only IRIs which can be written as the concatenation of the prefix with a local name (an alphanumerical string) are considered to be an _element of the namespace_, e.g. `http://www.wikidata.org/prop/P1234` is an element of the namespace `p:` but `http://www.wikidata.org/prop/something/else/P1234` is not an element. Furthermore, the mapping of the Wikibase data model to RDF syntax specifies that these namespaces can only be used in triples (or edges, for that matter) that connect specific namespaces. _The use of these namespaces is therefore restricted._ For example, an edge with a referent in the namespace `p:` can only have sources in the namespace `wd:` and only targets in the namespace `wds:`. @fig:rdf_mapping is an illustration taken from the Wikibase documentation on RDF mapping, which gives an overview of these restrictions.

/*```turtle
 wd:P22 a wikibase:Property ;
     rdfs:label "Item property"@en ;
     wikibase:propertyType wikibase:WikibaseItem ;
     wikibase:directClaim wdt:P22 ;
     wikibase:claim p:P22 ;
     wikibase:statementProperty ps:P22 ;
     wikibase:statementValue psv:P22 ;
     wikibase:qualifier pq:P22 ;
     wikibase:qualifierValue pqv:P22 ;
     wikibase:reference pr:P22 ;
     wikibase:referenceValue prv:P22 ;
     wikibase:novalue wdno:P22 .
```*/

#figure(caption: [An excerpt of customary IRI prefixes defined by Wikidata.],
```HTML
PREFIX p: <http://www.wikidata.org/prop/>
PREFIX pq: <http://www.wikidata.org/prop/qualifier/>
PREFIX pqv: <http://www.wikidata.org/prop/qualifier/value/>
PREFIX ps: <http://www.wikidata.org/prop/statement/>
PREFIX wd: <http://www.wikidata.org/entity/>
PREFIX wds: <http://www.wikidata.org/entity/statement/>
PREFIX wdt: <http://www.wikidata.org/prop/direct/>
PREFIX wdv: <http://www.wikidata.org/value/>
```
) <example:prefixes_in_wikidata>

#figure(caption: [An overview of restrictions for the use of namespaces in Wikibase @wikibase_rdf_mapping_graphic. The labels of the nodes and edges act as placeholders for specific IRIs, whose referents are within the namespace indicated by the label.],
  image("rdf_mapping.svg", width: 87%)
) <fig:rdf_mapping>


For further use a subset of these namespaces will be denoted by abbreviations.
  Let $Sigma$ be a valid alphabet for local names and $Sigma^*$ its Kleene closure.
  Let
  $f_bold(p), f_bold(q), f_bold(s) in I$ be _distinct_ IRIs.
  In analogy to the Wikibase data model, $f_bold(p)$ will denote the prefix for the namespace for *p*\roperties `p:`, $f_bold(q)$ for *q*\ualifying properties `pq:` and $f_bold(s)$ for *s*\tatements `ps:`. <def:prefix_formally>

= Querying <heading:querying>

Constructing a query for an RDF graph can be viewed as creating a subgraph — a set of RDF triples. In addition to valid RDF terms such as IRIs, blank nodes, and literals, now variables can be inserted at any position in the triple, instead of an RDF term. Each variable is distinct from all others and can be placed in multiple positions within the query graph. This query graph can now be looked as a stencil, where variables are like jokers in Scrabble. The database's query engine will try to find the same structure in the RDF graph and returns the RDF Terms which overlapped with a variable. This _matching_ is essentially the process of querying an RDF graph. Among other features, such stencils can be written using the RDF query language _SPARQL_, where this query graph or stencil is referred to as _Basic Graph Pattern_.

== SPARQL Protocol and RDF Query Language <heading:sparql>

The acronym _SPARQL_ is recursive and stands for *S*\PARQL *P*\rotocol *A*\nd *R*\DF *Q*\uery *L*\anguage and is part of the Resource Description Framework recommendation. It is considered to be a _graph based_ query language. The definitions of the following section are an excerpt from the _Formal Definition of the SPARQL query language_ @W3C_SPARQL_Formal_Definition. All relevant aspects of the formal definition are clarified in this work. Readers interested in further details are encouraged to consult the documentation directly.

This work focuses on a specific subset of SPARQL queries, specifically SPARQL-SELECT queries. SELECT queries can include additional components, such as value constraints, which restrict permissible variable assignments in the results. For instance, a constraint ensuring that e.g. an event occurred before 1900 would be expressed as `FILTER(?year < 1900)`. Such language features are not yet specified in the Visual Query Graph.

Other types of SPARQL queries also exist, such as `ASK` and `DESCRIBE`, which differ in the structures they return. These SPARQL query types and also the data manipulation language for triplestores will not be dealt with in this work. They are detailed in the SPARQL specification @W3C_SPARQL_Specification.

For further use, the set of all variables is from now on denoted by *$V$*. Following the syntax of SPARQL, variables in examples will be denoted with a leading question mark `?` followed by an alphanumerical word.

#definition[
  A *Basic Graph Pattern (BGP)* is a *subset* of SPARQL triple patterns @W3C_SPARQL_Formal_Definition
  $ (T union V) times (I union V) times (T union V). $
]<def:bgp>

#example[
  A valid Basic Graph Pattern following the query in @fig:example_query_introduction and visualised in @fig:screenshot_example_vqg would be
  $
    {
      &("?society", "instance-of", "natural research association"),\ 
      &("?society", "located-in", "Jena"),\
      &("?people", "member-of", "?society"),\
      &("?people", "career-statement", "?careerStatement")
    }.
  $
]

#definition[
  In essence, a *Graph Pattern* can contain multiple and optional *Basic Graph Patterns*. This work concentrates on queries which only contain one Basic Graph Pattern.
]<def:graph_pattern>

#definition[
  A *SPARQL-SELECT query* is a special SPARQL query, which consists of a Graph Pattern, a target RDF graph and a result form. The so-called result form specifies how the result of a SPARQL query looks like. In the case of SELECT queries it is a projection to the valid variable assignments for the given Graph Pattern. Alternative result forms include `ASK` and `DESCRIBE`. 
  The return tuple is determined by the query's projection statement, which specifies the subset of variables from the query to be included.
  The query results can be ordered using solution modifiers e.g. `DISTINCT`, `LIMIT` or `ORDER` (in analogy to SQL).
] <def:sparql_select_query>

#remark[
  Since a basic graph pattern can have any RDF Term as a subject, this implies, that a SPARQL query can query for a triple, which has a literal as its subject. An RDF graph however cannot have a triple with a literal as a subject.
]

Writing SPARQL queries is pretty straight-forward: The wanted structure
is expressed in terms of the query language, and the unknown parts are replaced by variables. Say the user wants to know which universities Goethe went to. The matching query would look like @example:goethe_query. IRIs are enclosed within angle brackets.
#figure(caption: [A SPARQL query to determine which educational institutions Goethe visited. Currently, the valid results are `wd:Q154804` (University of Leipzig) and `wd:Q157575` (University of Strasbourg). The structural components from @def:sparql_select_query are highlighted with comments.],
  ```HTML
  PREFIX wd: <http://www.wikidata.org/entity/> # for brevity
  PREFIX wdt: <http://www.wikidata.org/prop/direct/> # for brevity

  SELECT # result form
    ?institution # projection statement
  WHERE 
    { # graph pattern, in this case a basic graph pattern ...
      wd:Q5879 wdt:P69 ?institution . # ... with one entry
      # Johann Wolfgang von Goethe -- [educated at] -> Variable
    }
  ```
) <example:goethe_query>

In order to query a BGP containing a blank node, a query has to specify a variable at the blank node's position. There are other syntactical structures to express blank nodes, which are however semantically equal to using a variable @W3C_SPARQL_Formal_Definition. 

== Qualifiers <heading:qualifiers>
The naming, addressing, and definition of qualifiers in Wikibase is ambiguous @wikibooks_sparql_qualifiers @Erxleben2014_Wikidata_LOD. The term "qualifier" is used both for the syntactic structure and for the asserted RDF triple of an RDF graph. An achievement of this work is the dissemination of the terminology.

@fig:query_for_qualifier shows how a Wikibase qualifier can be queried. It is worth noting that different prefixes are used to refer to the Wikibase property `P69`, while yet another prefix is used for `P580`.

#figure(
  caption: [A query to fetch the start date of Goethe's education at the University of Leipzig],
```HTML
  PREFIX wd: <http://www.wikidata.org/entity/>
  PREFIX wdt: <http://www.wikidata.org/prop/direct/>
  PREFIX p: <http://www.wikidata.org/prop/>
  PREFIX ps: <http://www.wikidata.org/prop/statement/>
  PREFIX pq: <http://www.wikidata.org/prop/qualifier/>
  SELECT ?startDate WHERE {
      wd:Q5879 p:P69 ?implicit1 .     # these two lines 
      ?implicit1 ps:P69 wd:Q154804 .  # specify the qualified edge
      ?implicit1 pq:P580 ?startDate . # query for the qualifiers referent
  }
```) <fig:query_for_qualifier>

Obeying this modelling, a *qualifier edge* is an edge pointing from an element of the namespace `wds:` to an element of any namespace using a predicate in the `pq:` namespace.  The *value of a qualifier* is the target node of this edge. 

#definition[
  Let $Sigma$ be a valid alphabet for local names and $Sigma^*$ its Kleene closure.
  Any RDF triple with a predicate of the form $f_p u$ with $u in Sigma^*$ is a *qualifier*. 
]

#definition[
  Let $Sigma$ be a valid alphabet for local names and $Sigma^*$ its Kleene closure.
  Let $s in I$ be a subject, $b in B$ a specific blank node and $o, o' in I union L$ objects, which are all elements of $G$. Then, any subgraph $G_"QSn" subset G$ with
  $ 
    G_"QSn" &:= {(s, f_p u, b), (b, f_s u, o)}
  $
  is called *Qualified Statement in the narrow sense*, and $o'$ is called *Qualifier Value*,
  where $u, u' in Sigma^*$. Furthermore $G_Q subset G$,
  $
    G_"Q" &:= {(b, f_q u', o')},
  $
  is called qualifier to the Qualified Statement in the narrower sense.
  A *Qualified Statement in the broader sense* is the union of all qualified statements in the narrower sense to a specific blank node.
] <def:qualifiers>

#figure(
  caption: [A visualisation of a qualified statement with two qualifiers (the triples with the edges $q_1, q_2$) using the terms introduced in @def:qualifiers and $u,u',u''$ are valid local names. The boxes indicate the three subgraphs this qualified statement consists of: red box for the qualified relationship, green box for one qualifier and the violet box for the other qualifier. All nodes in this figure form the qualified statement in the broader sense.],
  image("Qualifier_abstract.svg", width: 60%)
)

= Mapping <heading:mapping>

// #todo[semantic-preserving an gegebener Stelle näher erläutern als "Die Ergebnisse sind die gleichen von beiden Formalismen"]

To establish a semantic-preserving mapping between Visual Query Graphs and SPARQL-SELECT queries, a formal specification for Visual Query Graphs is first introduced. Following this, the transformation function from a Visual Query Graph to SPARQL is defined. Lastly, the implementation of these functions is analysed and discussed.


== Visual Query Graphs and Basic Graph Patterns
The so far introduced structures include Basic Graph Patterns in SPARQL queries and RDF triples. While Basic Graph Patterns are used to describe stencils to be queried against RDF triples, the goal of Visual Query Graphs is to eliminate the need to manually model reified structures using blank nodes. Other literature @Vargas2019_RDF_Explorer uses the term Visual Query Graph to refer to a Basic Graph Pattern without Blank Nodes. This work uses the same term to define a graph with multi-edges, which consist of the same triples as the Basic Graph Pattern would, but with the exception, that any qualifier structures are replaced with a multi-edge, including all statements of the qualified statement in the broader sense.

In order to build a Visual Query Graph, we need special edges which involve all nodes of a qualified statement in the broader sense. This can be done using a hypergraph. A qualifier will be a hyperedge consisting between at least three nodes using at least two edges. All Basic Graph Patterns which are not qualified statements in the broader sense will be copied to the Visual Query Graph without any changes. All qualified statements will be exchanged for a hyper-edge, where the blank node is removed and the edges will be rebuilt using one directed hyper-edge. The visualisation of the hyper-edge in the VQG can be seen in @fig:vqg_with_qualifier.

#figure(
image("Qualifier_mit.svg"), caption: [Visual Query Graph with two Qualifiers. The equivalent SPARQL query should return two qualifier values. The qualifiers are highlighted using a violet and a green box.]) <fig:vqg_with_qualifier>


#definition[
  Let $G=(X,E)$ be a hypergraph. A hyperedge $(U, V) in E$ is defined as a 2-tuple, where $U in X$ are the source nodes and $V in X$ are the target nodes. A *labelled hyperedge* $(s, V)$ is a simplified hyperedge, between a source node $n$ and a set of labelled target nodes $(p,o) in V$ with label $p$ and target node $o$.
]

#definition[
  Let $Sigma$ be a valid alphabet for local names and $Sigma^*$ its Kleene closure.
  Let $G in (T union V) times (I union V) times (T union V)$ be a Basic Graph Pattern.
  Furthermore, let $N subset I union L union V$ be a set of nodes, $E subset N times (I union V) times N$ a set of edges, and $E_q subset N times cal(P)({f_s u | u in Sigma^*} union {f_q u | u in Sigma^*} times N)$ a set of labelled hyper-edges for qualified statements, where $cal(P)(X)$ denotes the powerset of a set $X$.
  Then the corresponding *Visual Query Graph* $G_q=(N,E,E_q)$ is a special directed hypergraph to a Basic Graph Pattern $G$ and constructed as follows:
  
    + Add all nodes except for blank nodes to the set of nodes $N$ of $G_q$.
    + Copy all elements of $G$ to the the set $E$ of $G_q$, but remove all Qualified Statements.
    
    + For each Qualified Statement $G_"QS"$ in the broader sense in $G$, create one labled hyperedge $e_q$ in $E_q$ as follows:
        + From the triples of the Qualified Statement in the narrower sense $Q_"QSn"$, add a tuple which omits the blank node and goes to the object: $Q_"QSn" subset Q_"QS"$, $G_"QSn" = {(s, f_p u, b), (b, f_s u, o)}, u in Sigma^*, o in N$. The labelled hyperedge $e_q$ is then $(s, {(f_s u, o)})$ and
        + for each qualifier to $G_"QS"$ of the form $(b, f_q u', o'), u' in Sigma^*, o' in N$ add a tuple $(f_q u', o')$ to the targets.
    
] <def:vqg>

#example[
  The Visual Query Graph $G_q = (N, E, E_q)$ illustrated in @fig:vqg_with_qualifier_formal would have the following sets (for brevity, the prefix `wd` for the items `Q5879` and `Q154804` are omitted):
  $
    N:= {("Q5879", "Q154804", "?eduEnded", "?eduStarted")},\
    E:= {},\
    E_q:= {
      ("Q5879", &{("ps:P69", "Q154804"),\ &("pq:582", "?eduEnded"),\ &("pq:580", "?eduStarted")})
  $
]

  #figure(
    caption:[Visual Query Graph with two qualifiers using the accurate Wikibase prefixes.],
    image("Qualifier_hypergraph.svg")
  )<fig:vqg_with_qualifier_formal>

#let vql_ops = (
   [User Interaction],
    [Adding a variable node],
    [Adding a literal node],
    [Adding a directed edge],
    [*Adding a qualifier*]
)

Following @Vargas2019_RDF_Explorer, the VQG is _constructed_ using the _Visual Query Language (VQL)_, consisting of #{vql_ops.len()-1} algebraic operators, which will correspond to atomic user interactions in the user interface (see @fig:ops_in_vql).

#figure(
  caption: "Operations in the VQL",
  table(columns: 1,
  ..vql_ops
  )
) <fig:ops_in_vql>

Using this new VQG and VQL, we can now create an intuitive visualisation (see @fig:vqg_with_qualifier) as motivated by @Simons_Blog_Entry_Graphic_query. The mapping from Visual Query Graphs to Basic Graph Patterns follows the definition of the construction.

// TODO! describe the details of how the VSQ hyperedges get used by the implementation to construct a valid RDF graph


== Implementation <heading:implementation>

#todo[
  My work also has the advantage, that all conventions are regulated in a configuration file specifically for data sources. A user (in the future) can add
  new conventions at a central place and will know, which effects changes have.

  an geeigneter Stelle einfügen:
  #remark[
  For this work, the Wikibase namespaces `wd` for directly addressing items and `wdt` for addressing properties are generally adequate. However, the program allows users the flexibility to define custom prefixes that deviate from these conventions, a capability reflected in this definition.
]
]

The goal of this work is to create two program parts:
+ the _visual query building interface_ (forthon called *frontend*) and
+ the _translator between VQG and SPARQL_ (forthon called *backend*).

The most important aspects for the choice of software and UX design were usability and maintainability. The aim is to lay the basis for a software, which can be applied in day-to-day use as an "almost-no-code" query builder. 
//TODO: nächsten satz in Diskussionsteil verschieben
The development of Query by Graph will continue as part of the #link("https://dfg.de/")[DFG] project _HisQu_, with the active involvement of the #link("https://www.mephisto.uni-jena.de/")[MEPHisto group], which will further advance this work. 
Therefore, this work's focus lay on building an extensible, future-proof platform,
// TODO: Rechtfertigungen vernmeiden die nicht substantiell zum Endprodukt beitragen und was nicht zur Implementation selbst beiträgt in den Dikussionsteil verschieben
rather than implementing every thought-of feature. During my work on this thesis, I received a request to use my program in a digital humanities seminar. To support its advancement, Patrick Stahl assisted with implementation of UI features. All changes are documented and traceable in the repository's history#footnote[https://github.com/HerrMotz/bachelor-thesis].

=== Architecture
Given RDF's predominant use in web contexts, opting for a web application was a natural choice. The backend was designed to be both explainable and traceable. While several functional programming languages are well-suited for this purpose, Rust#footnote[http://www.rust-lang.org] emerged as the preferred option due to its ability to compile to WebAssembly#footnote[http://webassembly.org], enabling native execution in a browser. 

#todo[Das hier hört sich nicht natural an, es ist mir ncith so richtig klar, was das noch für advantages hat die nicht schon vorher gesagt wurden und warum. Entweder ausführen was für weitere advantages, oder streichen. Extensible, Efficient and maintain formal precision -> in welcher Hinsicht? Hier vielleicht konkretisieren oder streichen.]

This approach offered a compelling advantage over a traditional server-client architecture. The resulting combination of architectures is extensible, efficient, and maintains formal precision.

#todo[Mention, that I am limited to two prefixes, wdt and wd. Also mention, that there is a configuration file, which contains all Wikibase data sources. ]

The *frontend* was developed using TypeScript, Vite, Vue3, ReteJS, and TailwindCSS, all licensed under the MIT license. Its purpose is to allow the user to
+ build a VQG, and edit it from the SPARQL code editor,
+ searching for items and properties in arbitrary Wikibase instances using the API,
+ display meta-information on items and properties,
+ configure Wikibase data sources and
+ handle all data source specific tasks (such as enriching entities with information from a the Wikibase API).

The *Wikibase data sources* are configured by the user and stored in the browser's local storage. Following the conventions of Wikibase, the choice was made to only allow one prefix for items and one for properties. The program assumes, that the item prefixes point directly to the item, e.g. `wd` for Wikidata, and the property prefixes to the property value, e.g. `wdt` (for reference on the data model see @fig:rdf_mapping). This assumption is based on the premise that users writing queries involving more than this level of abstraction, typically have a deeper understanding of the underlying mechanics and are likely capable of composing an adequate SPARQL query. The implementation, however, adheres to the query graph specification and supports the use of arbitrary prefixes.

The *backend* is designed to parse SPARQL queries into Query Graphs and convert them back. It utilises the `spargebra`#footnote[https://docs.rs/spargebra/latest/spargebra/] library for parsing SPARQL queries, though this library is still under development. Verifying the correctness of the parser lies outside the scope of this work. Nevertheless, it was confirmed that the parser produced correct results for randomly generated SPARQL-SELECT queries with BGPs.

To ensure compatibility between the backend and frontend, both adhere to strict types. The edge lists are exchanged using JSON serialisation and de-serialisation.
An entity is considered to have the properties shown in the listing below. #todo[change the reference, if the bug is fixed or I rendered it externally.] 

#todo[Rephrase so that it is clear that they both use *the same* types. Der Hauptpunkt, ist dass ich das Rust so geschrieben habe, dass es eine Übergabestelle für andere Programme sein könnte.]

The VQG is exported in the form of an edge list from the frontend to the backend. The elements of the edge list are triples, corresponding to BGPs, and each entry of the triple is a literal, variable or IRI --- or to use Wikibase terminology, an entity. The BGPs in turn are mapped to a SPARQL-SELECT query with all variables from the VQG added to the projection. #todo[Check if this is still the case when I am finished with the qualifier feature, or whether I leave out the blank-node-placeholder variables.]


=== Modelling Visual Query Graphs in the Implementation
#figure(caption: [Key Data Types for the translation between VQG and SPARQL.],
```pintora
classDiagram
  class PREFIX {
    string iri
    string abbreviation
  }
  class WIKIBASEDATASOURCE {
    string name
    PREFIX propertyPrefix
    PREFIX itemPrefix
    string[] preferredLanguages
  }
  class ITEM {}
  class PROPERTY {}
  class ENTITY {
    string id
    string label
    PREFIX prefix
    WIKIBASEDATASOURCE dataSource
  }
  ENTITY <|-- ITEM
  ENTITY <|-- PROPERTY
  
  class CONNECTION {
    PROPERTY property
    ITEM source
    ITEM target
  }
  PREFIX "1" o-- "*" ENTITY
  PREFIX "2" o-- "*" WIKIBASEDATASOURCE

  ENTITY "*" --o "1" WIKIBASEDATASOURCE
  
  CONNECTION "2" o-- "*" ITEM
  CONNECTION "1" o-- "*" PROPERTY
```
)

#figure(caption: [Restructured data types for VQGs.],
```pintora
classDiagram
  class WIKIBASEDATASOURCE {
    string name
    PREFIX propertyPrefix
    PREFIX itemPrefix
    PREFIX qualifierPrefix
  }
  class ITEM {}
  class PROPERTY {}
  class QUALIFIER {
    PROPERTY property
    ITEM target
  }
  class ENTITY {
    string id
    string label
    PREFIX prefix
    WIKIBASEDATASOURCE dataSource
    QUALIFIER[] qualifiers?
  }
  ENTITY "*" --o "1" WIKIBASEDATASOURCE
  ENTITY <|-- ITEM
  ENTITY <|-- PROPERTY
  PROPERTY "1" *-- "*" QUALIFIER
```
)

= Discussion <heading:discussion>

A central focus of this work was the analysis of Wikibase conventions and the development of precise and adequate descriptions. The existing documentation on these conventions lacks terminological clarity, which poses challenges for new users attempting to familiarise themselves with the system. By introducing well-defined terminology and systematically guiding readers through the conventions, this work aims to provide a structured introduction to the technical intricacies of Wikibase.

In comparison to other approaches such as @Vargas2019_RDF_Explorer @SPARQLVis, #todo[Ich muss nochmal die Referenzen prüfen. Finde die anderen Arbeiten nicht.] this work distinguishes itself through its emphasis on user experience design and responsiveness. As noted earlier, even a limited user study involving digital humanities students demonstrated that the program can be effectively utilised with minimal training—an observation also made by @Vargas2019_RDF_Explorer in their user study. Still, a full user study is necessary to validate this claim. Unlike @Vargas2019_RDF_Explorer, which presents all possible assertions for an item and requires the user to select the next assertion, this work enables users to freely add nodes and edges without needing to specify their content in advance. While it is hypothesised that this represents a significant improvement in usability, a formal user study will be necessary to validate this claim.

A simple, but fundamental enhancement is the configuration of and switching between Wikibase data source during the use of Query by Graph. This allows to add items and properties from more than one Wikibase instance and makes the user experience more intuitive.

Another significant advantage is the inclusion of implementation-specific RDF constructs for Wikibase, currently focusing on qualifiers. The application of these constructs are particularly common in the digital humanities but are challenging to query due to their specialised triple structures and the required prefixes. Manually writing such queries often leads to small errors, which can result in empty results with no clear explanation. Query by Graph addresses this issue by introducing a dedicated visualisation for qualifiers within the Visual Query Graph, thereby eliminating this common source of mistakes.

Another limitation is the inability to represent multi-edges in the Visual Query Graph. This feature would allow specifying multiple valid properties between two items. Given the community-driven nature of Wikibase, mistakes often occur and may go unnoticed for some time. For instance, in Wikidata, the term "student" yields several results, such as `wdt:P802` ("student"), `wdt:P1066` ("student of"), and `wdt:P69` ("educated at"). A user could by accident or for good reason choose one of the three properties to make an entry. A user writing a query could draw multiple edges and choose to ignore the differences or to filter using different means, e.g. using an `instance-of` property. @Vargas2019_RDF_Explorer technically supports this through the use of `FILTER` and `REGEX` statements. However, this feature could be made much more accessible in a specialised Visual Query Graph representation.

In future work, following the approach of @Sparnatural, integrating an ontology to provide pre-built structures that users can drag and drop onto the sketching board would be highly beneficial. A major limitation of @Sparnatural is its reliance on an ontology for _every_ query. In contrast, Query by Graph allows any valid Query Graph to generate a SPARQL-SELECT query with a BGP. This allows to derive Query Graph fragments from ontology snippets. For instance, a relationship like `grandchildren` could be defined in OWL and translated into a Query Graph fragment such as `{(?children, parents, ?parents), (?grandchildren, parents, ?children)}`. An abstraction layer could then expose only the derived grandchildren, presenting this relationship as a single node in the _Visual_ Query Graph.

Currently, Query by Graph supports only SPARQL-SELECT queries with a single Basic Graph Pattern. Future work could explore the feasibility of visualising optional graph patterns and incorporating support for value constraints using `FILTER`-statements. However, there is a practical limit to implementing these features, as the visual representation may eventually become less intuitive than directly using SPARQL syntax.

The architecture of Query by Graph also poses the grand advantage, that an arbitrary query adhering to the current limitations can be imported and visualised. The only other implementation supporting this requires an ontology @Sparnatural. Furthermore, the SPARQL query can be changed while using the editor, where the changes are directly applied to the Visual Query Graph. Moreover, the correspondences in the respective other representation could be highlighted, e.g. the cursor position in the SPARQL query editor highlights a node or edge in the Visual Query Graph and vice versa.

Lastly, the implementation of Query by Graph currently only supports string literals. The user interface will receive special fields for all XML Schema Definition types.

Also, Wikibase makes use of labels which could be added to the query. And the query could be directly executed from Query by Graph and the results displayed as e.g. a graph.

#set text(size: 0.8em)
#figure(
  caption: [An overview of all features currently implemented.\ #text(size:.8em)["#sym.checkmark" means implemented and tested, "(#sym.checkmark)" means implemented but not bug-free and "#sym.crossmark" means not implemented. A full feature list can be found in the technical documentation of the repository.]],
  table(columns: (1fr, 70pt, 60pt, 60pt),
    [Feature\ Description], [Query by Graph\ (this work)], [RDF\ Explorer @Vargas2019_RDF_Explorer], [Spar-\ natural @Sparnatural],
    [Drawing a VQG with variables and literals], [#sym.checkmark], [#sym.checkmark], [#sym.checkmark],
    [Searching for entities on multiple Wikibase instances], [#sym.checkmark], [(#sym.checkmark)], [(#sym.checkmark)],
    [Creating SPARQL-SELECT queries from a VQG], [#sym.checkmark], [], [],
    [Code editor for SPARQL queries], [#sym.checkmark], [], [],
    [Applying changes in the code editor to the VQG], [(#sym.checkmark)], [], [],
    [Enriching unseen entities with metadata from the Wikibase API], [(#sym.checkmark)], [], [],
    [Literals with standard RDF data types (string, int, date, ...)], [(#sym.checkmark)], [], [],
    [Use multiple Wikibase instances as data sources], [#sym.checkmark], [], [],
    [Meta-Info Panel], [#sym.checkmark], [], [],
    [Rendering qualifiers with the proposed visualisation], [#sym.crossmark], [], [],
    [Value Constraints], [#sym.crossmark], [], [],
    [Result Modifiers (e.g. `ORDER`, `LIMIT`)], [#sym.crossmark], [], [],
  )
)

#set text(size: 1em)

#todo[Man könnte noch etwas mit LLMs machen, aber das ist jetzt hier glaube ich genug.
bspw.
  - "what are possible relations between a variable and an item" und man gibt noch mit was man modellieren will. Im Hintergrund wird abgefragt welche Relationen es gibt und welche davon ähnliche Bedeutungen haben wie das vom Nutzer angefragte. Das könnte man schrittweise für einen ganzen Graphen machen (neuro-symbolic AI :)))
    - Das wäre besser als einfach nur zu versuchen eine natürlichsprachliche Frage in eine SPARQL query zu übersetzen, weil sich das nicht an den konkret vorhandenen Relationen orientiert.
]

= Declaration of Academic Integrity

#todo[Last edited: January 2024, check for a newer version when I submit]

1. I hereby confirm that this work — or in case of group work, the contribution for which I am responsible and which I have clearly identified as such — is my own work and that I have not used any sources or resources other than those referenced.

   I take responsibility for the quality of this text and its content and have ensured that all information and arguments provided are substantiated with or supported by appropriate academic sources. I have clearly identified and fully referenced any material such as text passages, thoughts, concepts or graphics that I have directly or indirectly copied from the work of others or my own previous work. Except where stated otherwise by reference or acknowledgement, the work presented is my own in terms of copyright. 
   
2. I understand that this declaration also applies to generative AI tools which cannot be cited (hereinafter referred to as "generative AI").

  I understand that the use of generative AI is not permitted unless the examiner has explicitly authorised its use (Declaration of Permitted Resources). Where the use of generative AI was permitted, I confirm that I have only used it as a resource and that this work is largely my own original work. I take full responsibility for any AI-generated content I included in my work. 
   
  Where the use of generative AI was permitted to compose this work, I have acknowledged its use in a separate appendix. This appendix includes information about which AI tool was used or a detailed description of how it was used in accordance with the requirements specified in the examiner#sym.quote.single\s Declaration of Permitted Resources. I have read and understood the requirements contained therein and any use of generative AI in this work has been acknowledged accordingly (e.g. type, purpose and scope as well as specific instructions on how to acknowledge its use). 

#todo[Check whether #sym.quote.single is the right thing to use here.]

3. I also confirm that this work has not been previously submitted in an identical or similar form to any other examination authority in Germany or abroad, and that it has not been previously published in German or any other language. 

4. I am aware that any failure to observe the aforementioned points may lead to the imposition of penalties in accordance with the relevant examination regulations. In particular, this may include that my work will be classified as deception and marked as failed. Repeated or severe attempts to deceive may also lead to a temporary or permanent exclusion from further assessments in my degree programme. 

#v(40pt)
#grid(columns: (1fr, 1fr), row-gutter: 1em,
  line(length: 150pt, stroke: (dash: "dashed")),
  line(length: 200pt, stroke: (dash: "dashed")),
  "Place and date",
  "Signature"
)
