#import "ilm.typ": *
#import "@preview/xarrow:0.3.0": xarrow, xarrowSquiggly, xarrowTwoHead
#import "@preview/equate:0.2.1": equate

// for definition and example subheadings
#import "@preview/great-theorems:0.1.1": *
#import "@preview/rich-counters:0.2.2": *

#set text(lang: "en", region: "GB")
#show: great-theorems-init

#let spct = sym.space.punct
#let examiner = [Prof.#spct\Dr. Clemens Beckstein\ M.#spct\Sc. Johannes Mitschunas]
#let degree = [Bachelor of Science (B.#spct\Sc.)]

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
  //   examiner: examiner,
  //   place-and-submission-date: "Jena, 12. Januar 2025",
  // ),

  cover-english: (
    faculty: "Faculty for Mathematics and Computer Science",
    university: "Friedrich Schiller University Jena",
    type-of-work: "Bachelor Thesis",
    academic-degree: degree,
    field-of-study: "Computer Science",
    author-info: "15 July 2001 in Chemnitz, Germany",
    examiner: examiner,
    place-and-submission-date: "Jena, 12 January 2025",
  ),
  
  abstract: [
    I propose a collection of tools for building and running SPARQL queries for complex RDF databases with the support of formal ontologies, which are neatly composed into one and given the name Query by Graph. #todo[Rephrase and add]
  ],
  
  preface: align(left)[
    #todo[Write a heartwarming preface.]
  ],
  
  appendix: [
    #set heading(outlined: false)
    #todo[This chapter should contain all code listings, figures, tables and so on.]
    == Use of Generative AI
    This bachelor thesis was written in assistance of the OpenAI large language models GPT-4o and GPT-o1 preview. The large language models were used at the very start to get an overview over the domain, to ease literature research and to point out stylistic, orthographical and grammatical mistakes to the writer. The models were _not_ used to generate passages of this work. 
  ],
  
  abbreviations: (
    ("W3C", "World Wide Web Consortium (registered trademark)"),
    ("RDF", "Resource Description Framework"),
    ("RDFS", "Resource Description Framework Schema (Ontology within RDF)"),
    ("SPARQL", "SPARQL Protocol And RDF Query Language (recursive acronym)"),
    ("IRI", [Internationalised Resource Identifier (see @heading_iri)]),
    ("OWL", "Web Ontology Language"),
    ("VQG", "Visual Query Graph (user-built query graph)"),
    ("API", "Application Programming Interface"),
  ),

  external-link-circle: true, // TURN THIS OFF IF YOU GENERATE THE PRINT VARIANT
  
  figure-index: (enabled: true),
  table-index: (enabled: true),
  listing-index: (enabled: true),
  bibliography: bibliography(title: "Bibliography", style: "institute-of-electrical-and-electronics-engineers", "bib.yaml")
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
  font: "Cascadia Code",
  weight: 300,
  ligatures: true,
  discretionary-ligatures: true,
  historical-ligatures: true,
)

/* END Custom Environment */

= Aim and Relevance
/*#todo[

Contents of Aim and Relevance
- Context: make sure to link where your work fits in
- Problem: gap in knowledge, too expensive, too slow, a deficiency, superseded technology
- Strategy: the way you will address the problem  

I should also state some general information:
- comment on employed hardware and software
- describe methods and techniques that build the basis of your work
]*/

== Problem <problem_heading>
Much of the mankind's knowledge is stored in the format of natural language, which can not be accessed without following these steps: 1. rough research on a topic, 2. formulate a question using this map, 3. finding relevant literature to the question, 4. reading the literature, 5. extracting the relevant facts and, 6. reading more literature because the question is more complex than you thought 7. inferring an answer from the retrieved facts. This process can prove to be tedious and many of these steps have been eased for us -- may it be in the form of a librarian or a search engine.
 
The currently most used search engine, Google, uses of course Network Analysis but also Natural Language Processing (NLP) to identify the most relevant results to a topic. And just in recent years Large Language Models (LLMs) have shown interesting capabilities in compressing loads of knowledge using statistical analysis. A LLM is capable of giving an outline of any given topic or question, similar to a librarian, however any response is endangered by confabulation and ought to be verified. So, we successfully taught the computer to handle natural language for specific use cases somewhat reliably. But we might just go the last mile and ...

... let humans formalise knowledge in a computer readable format. Using a formal ontology any given relationship can be theorised and translated into a form processible by computers. This poses as a two-fold advantage: Any statement is put down in clearly interpretable terms and is viewed agnostically concerning eloquence. The difficulty of a formal ontology however, is to think of all (or at least most) things ought to represented in advance. Therefore, ontologies require careful deliberation and their genesis usually goes by the saying: "Many cooks spoil the broth". Collaboration in ontology development is a real challenge but a necessity. Yet, it is difficult to find one ontology to fit all needs.

So, how could this process be eased, whilst not giving up the advantages of computer-processability? Originally conceptualised by Tim Berners-Lee, the W3C#sym.trademark.registered standardised the Resource Description Framework (RDF). While an ontology consist of a theory (T-Box) and assertions (A-Box, statements which are in compliance with the theory) a RDF knowledge base can consist purely of an A-Box. The T-Box is quietly implicit. Using an RDF schema, a taxonomy can be added (at any time), usually using an "instance-of" assertion, but consistency is no inherent obligation of an RDF database#footnote[although it is obviously good practice to be consistent with the RDF schema].

This "formalise as you go"-approach allows for maximal flexibility of the data model and proves advantageous e.g. in the digital humanities. Recently, historians, among others, started to use centralised RDF databases, allowing for collaboration on research questions and finding connections between the results from different researchers. A grand initiative called FactGrid#footnote[http://factgrid.de -- based out of Erfurt/Gotha/Jena] advertises the use of their public RDF database in the hope of creating synergy effects for future research.

This directly leads to the relevance of this work: RDF databases can only be potently queried using a query language called SPARQL. Most researchers working in the human sciences, such as history, do not have a degree in computer science. Therefore the creation of SPARQL queries pose a challenge. Visual query helpers #todo[list them here] exist, but are limited in their query complexity #todo[quote]. The aim of this work is to lay the groundwork for a visual query builder, which enables a previously unintroduced user to create maximally complex SPARQL queries using a visual interface. This work is heavily inspired by Olaf Simons @Simons_Blog_Entry_Graphic_query.

/*
Most factual knowledge can easily be written in terms of relations between individuals.

#todo[
  Therefore challenges are:
  - Making information in an RDF databases understandable and not so abstract for a human interpreter (for example visualising the result in a graph)
]

#todo[Connect the following to somewhere:]

RDF databases store large amounts of validated data and are freely available, however, they:
- can only be potently queried using SPARQL, which is not intuitive for non-programmers,
- can be looked at using several interfaces, which however lack inference capabilities,
- usually contain no formal ontology to inference on their data,
- can hardly automatically be made consistent with a formal ontology and
- allow for no systemic consistency checks (i.e. those have to be ran as post-hoc batch jobs).*/

== Proposed Solution
This thesis aims to explore methods and concrete implementation, which guides the user through the process of finding an answer to a given question in an RDF database. This includes:

- enabling a layman to create complex SPARQL-select-queries using a visual interface, #todo[find a pretty abbreviation for SPARQL-select-queries and change every occurrence in the document and write a macro which detects these occurrences and marks it as an error]

- allow changes to the SPARQL-select-query, which will in turn change the graph in the visual interface

For this, I decided to develop a web application, which at its heart has Rust-code to translate visually built queries to SPARQL queries.#footnote[The code is publicly available at #link("https://github.com/HerrMotz/bachelor-thesis/")[`github.com/HerrMotz/bachelor-thesis`].]

== Related Works

=== RDF Explorer

The approach by Vargas et al. @Vargas2019_RDF_Explorer is to show all possible assertions about an object #todo[Is "object" the right word?] already while building the query. The goal is to guide the formulation of the user's question from a known starting point. This approach uses a fuzzy search prompt for an RDF resource as a starting point. After adding an object from the prompt results to the drawing board, the user can select from a list of all relations to other objects to augment the prompt. The user may also leave the relation unspecified, add a new object and select from a list of all assertions between these two objects. A user may just as well choose to let any object or property be a variable.

#example[
  The _Wikidata_ object `wd:Q5879`, also known as _Johann Wolfgang von Goethe_, offers several possible assertions, such as that he is "instance of" human and that he was "educated at" the University of Leipzig. This approach shows these in a sidebar, implying that those might be sensible next steps to specify a question.
]

Compared to writing a complex query manually, this approach offers feedback on which queries may yield a result. The user does not even need to run the generated SPARQL query, because the result is already clear from the explorer interaction.

#todo[Olaf Simons was puzzled, which sense it makes to run the SPARQL query afterwards, because the result is already clear from the interaction.]

A demonstration is available at https://rdfexplorer.org.

=== Exploring KGs (also Vargas)
@Vargas2020_UI_for_Exploring_KGs
#todo[
  Summarise
]

=== RDF2Graph
This approach by van Dam et al. @vanDam2015_RDF2Graph conceptualises special RDF resources, which contain _class_ and _subclass_ assertions for its objects. From this information a network of classes can be extracted, which can be used to visualise the possible relations between instances of classes in the resource. This approach was proven to be useful for resources on biology, e.g. #link("https://www.ebi.ac.uk/chebi/")[ChEBI] and #link("https://sapp.gitlab.io/docs/index.html")[SAPP]. Unfortunately, the approach does not discuss the modelling challenges for resources with incomplete, inconsistent or missing class relations.

=== NLQxform
https://www.semanticscholar.org/paper/NLQxform%3A-A-Language-Model-based-Question-to-SPARQL-Wang-Zhang/159ee26c0c2666b3e18814857b4a4d4182ed8246

=== Smeagol: A "Specific-to-General" Query Interface Paradigm

=== Obi-Wan: Ontology-Based RDF Integration of Heterogeneous Data


=== Knowledge Graph Exploration for Laypeople
@KnowledgeGraphExplorationForLaypeople
#todo[Summarise]


=== Conceptual Navigation in Large Knowledge Graphs 
@ConceptualNavigationInLargeKnowledgeGraphs
#todo[Summarise]

=== Connecting Ontologies and RDF Databases 
@Arakawa2023_SugarBindRDFOntology
#todo[Summarise]

=== Relevant Takeaways
Visual Interfaces seem to be promising advantages in the research community and are relevant.
#todo[Build a bridge between related work and my work]

#todo[Make the summaries of other papers more concise, so that it can be put into one running text]

= Fundamentals

== Semantic Technologies
#todo[

Questions, which I would like to be answered in this chapter:
- How can information about the real world be represented in a computer?
- What are RDF databases in comparison to other semantic technologies?
- What is the advantage of using a strict formal ontology in comparison to an RDF database?
]
@Dengel2012_Semantic_Technologies

// (There are Springer conferences on semantic web technologies: https://suche.thulb.uni-jena.de/Record/1041330375?sid=49057082)

Computers generally lack information about the environment humans live in. For example, unless formalised, a computer is unaware of the fact, that an arbitrary arrangement of numerals separated by lines, such as `8/7/2000`, is supposed to represent a date within a calendar based on the birth of a religious figure. How would a human even know of this convention, if it were not taught to him? And even with this knowledge, one can easily stumble upon a false friend: Here, I picture a European fellow confronted with an American booking confirmation. The American interprets the above date as August 7th in the year 2000. In the worst case, the European confidently interprets it as July 8th and would probably be wrong. Explicating the date format would have prevented this disaster.

The original idea by Tim Berners-Lee was to annotate web pages using a well-defined common vocabulary, so that any computer can, without human assistance, extract the relevant contents of a website. For example, a doctors office might post opening times on their website. Using a well-defined and public vocabulary, the website describes a table as "opening times" and the strings of weekdays and times as entries of the opening times. #todo[insert example code from the book on Semantic Technologies] @Dengel2012_Semantic_Technologies. This concept is not necessarily limited to websites, but can just as well be applied for any data storage. These deliberations waged the establishment of standards for describing meta information, such as:

- Resource Description Framework (see @heading_rdf_standard)
- Web Ontology Language (@heading_owl)
- #todo[List more from the book @Dengel2012_Semantic_Technologies]


== RDF Standard <heading_rdf_standard>
The W3C#sym.trademark.registered recommends a standard for exchange of semantically annotated information called the Resource Description Framework (RDF) standard model. The most notable recommendations are

- the RDF graph format and triples (see @heading_triples),

- the Internationalised Resource Identifier (@heading_iri) and

- the query language SPARQL (see @sparql_heading).

#todo[
- What are alternatives to RDF databases?
- How do RDF databases work?
- Which query languages work / are used on RDF databases?
]

#todo[
  What is a reifier good for/used for (irl)?
]

=== Graphs and Triples <heading_triples>

An *RDF graph* is a set of RDF triples. An RDF triple is said to be asserted in an RDF graph if it is an element of the RDF graph @W3C_RDF_1.2_Proposal.

#definition[
  Let *$I$* denote the set of IRIs, *$B$* denote the set containing one blank node $circle.dotted$, *$L$* denote the set of literals and *$V$* denote the set of query variables. Let
  subject $bold("s") in bold("I") union bold("B")$,
  predicate $bold("p") in bold("I")$ and
  object $bold("o") in bold("I") union bold("L") union bold("B")$.

  Then, following @W3C_RDF_1.1_Reference, any three-tuple or triple in an RDF graph is of the form

  $
    (bold("s"), bold("p"), bold("o"))
  $
  #align(center)[or equivalently]
  $ 
    bold("s") xarrow(bold("p")) bold("o"),
  $ <def_spo>
]

if subject *$s$* relates to object *$o$* in a way which the predicate *$p$* describes.

#example[
  Suppose a subject is given the name "Johann Wolfgang von Goethe", which relates to an object of the name "University of Leipzig", in the way, that the subject was a student at the object. Using the formalism from @def_spo, one might be inclined to produce something like:
  $
    bold("s") := "Johann Wolfgang von Goethe", \
    bold("p") := "educated at", \
    bold("o") := "University of Leipzig",
  $
  $
    "Johann Wolfgang von Goethe" xarrow("educated at") "University of Leipzig."
  $ <ex_spo_goethe>
]

=== Internationalised Resource Identifier <heading_iri>

Internationalised Resource Identifiers (IRIs) [#link("https://www.ietf.org/rfc/rfc3987.txt")[RFC3987]] are a superset of Uniform Resource Identifiers (URIs) [#link("https://www.ietf.org/rfc/rfc3986.txt")[RFC3986]]. Their purpose is to *refer to a resource*. The resource an IRI points at is called *referent*. 

The main advantage of IRIs over URIs are their enhanced character set. However, the details are not directly relevant to this work, therefore I will simply refer to the quoted RFCs for further reading.

=== Literals

The definitions in this section follow the *RDF v1.2* specifications @W3C_RDF_1.2_Proposal, which, at the time of writing, is a working draft#footnote[RDF *v1.1* @W3C_RDF_1.1_Reference only allows for the first three elements.]. Again, the technical specifications are not directly relevant to the matters of this work, therefore I will abstract from the implementation details. 

#definition[
  A *literal* in an RDF graph can be used to express values such as strings, dates and numbers. It can have two elements:
  + a *lexical form*, which is a Unicode string,
  + a *data type IRI*, which defines the mapping from the lexical form to the literal value in the user representation. (also note the remark below this list)
  + a *language tag*, which allows to add express from which language the *lexical form* stems and
  + a *base direction tag*, which occurs in combination with the *language tag* to indicate the reading direction (left-to-right or right-to-left).

  _Remark: The necessity of the language and base direction tag are indicated by two separate *special IRIs*._
]

#definition[
  The *literal value* of a *literal* in an RDF graph is defined in dependence of the fields available in the *literal*. These will be reffered to as literal types. The literal value is a tuple. 

  #align(center, table(columns: 2, align: horizon,
    [Literal Type], [Literal Value],
    [has language tag], [(lexical form, language tag)],
    [has direction tag], [(lexical form, language tag, base direction tag)],
    [has IRI stated in the\ #link("https://www.w3.org/TR/rdf12-concepts/#dfn-recognized-datatype-iri")[list of recognized data type IRIs]], [the literal value interpreted\ as the indicated data type]
  ))
]

=== Blank nodes
#todo[Write this section!]

/*=== Modelling Information using Triples

Suppose, that the assertion from @ex_spo_goethe is part of the A-box of an RDF database. It can be deducted that:
#todo[such statements are called entailments]:
- there is something called "Johann Wolfgang von Goethe",
- using the assumption that a different symbol implies a different object, there is something different from Goethe, called "University of Leipzig",
- there is a directed relation called "educated" at and
- of course the assertion itself, meaning that the relation applies between these two objects.

A computer still does not understand what it means to be educated at some place or where Leipzig is, but it can interact with this information in a formally correct way. The human operator can construe meaning, an interpretation grounded in the real world, in to the assertion. 

However, for any structured querying to be possible, the databases ought to be filled according to certain conventions. Preferably such conventions that are interoperable with other data sources (see @heading_lod).*/

=== Qualifiers
Most real-world relationships might present to be more complex than something one would want to model in a single triple. For example, one may want to express that "Goethe" was educated at the "University of Leipzig" from 3 October 1765 to 28 August 1768. One possibility is to let relationships have more than two operands, i.e. increase the arity by one for each additional parameter. "Educated at" would then be called "educated at (#sym.dot) from (#sym.dot) to (#sym.dot)". Another way using the limited triple syntax is to create an implicit object, that assists in modelling the relationship. We use it to describe a new concept; a human might be inclined to give it a name, e.g. "educated at for a certain time". The triples exemplify a *qualified statement* as seen in Wikibase instances: #todo[Rework formulation]
$
  "Goethe" &longArrow("educated at") && "Uni Leipzig", \
  "Goethe" &longArrow("educated at") && "Implicit1", \
  "Implicit1" &longArrow("educated at") && "Uni Leipzig", \
  "Implicit1" &longArrow("started at") && 3.10.1765, #<ex_qualifier_1> \
  "Implicit1" &longArrow("ended at") && 28.08.1768.  #<ex_qualifier_2>
$ <assertions_goethe_education>

Having specified such an implicit concept for our concept "educated at for a certain time", one is free to add a few extra statements about what he studied and whether he graduated:

$
  "Goethe" &longArrow("educated at") && "Implicit1", \
  "Implicit1" &longArrow("educated at") && "Uni Leipzig", \
  "Implicit1" &longArrow("started at") && 3.10.1765, \
  "Implicit1" &longArrow("ended at") && 28.08.1768, \
  #text(fill: green)[Implicit1] &longArrow("field of study") && #text(fill: green)[Law], \
  #text(fill: green)[Implicit1] &longArrow("graduated") && #text(fill: green)[True]
$ <assertions_goethe_education_revised>

#definition[
  Let 
  $s in L union I$ be a specific subject,#sym.space.med
  $p_i in P' subset.eq I, i in NN$ an arbitrary collection of predicates,#sym.space.med
  $o_j in O' subset.eq L union I, j in NN$ an arbitrary collection of objects,#sym.space.med
  $b in B$ a blank node. 
  Then, a *qualified statement* is defined as a set containing the triples
  $
      &(s&, &p_1, &o_1) #<def_qualifier_redundancy>\
      &(s&, &p_1, &b)\
      &(b&, &p_1, &o_1)\
      &(b&, &p_i, &o_j) #<def_qualifier>\
  $
  and staments such as @def_qualifier are called *qualifiers*.
]

#remark[This definition follows the Wikibase implementation. The term "qualifier" is not used or specified in the RDF references @W3C_RDF_1.1_Reference @W3C_RDF_1.2_Proposal. The redundant statement @def_qualifier_redundancy is rectified through the necessity to resolve a query for an assertion of the form $(s, p_1, o_1)$.]

This method of describing information allows us to implicitly define new concepts. Any program dealing with qualifiers merely handles the explicit assertions for an anonymous concept. But, this anonymity poses a challenge to a human interpreter; implicit concepts usually remain unnamed (#todo[todo below (how does it work)]).

#todo[How do qualifiers actually work in the context of the spec @W3C_RDF_1.2_Proposal? Do they use blank nodes?]

#todo[How do qualifiers get their name in Wikidata?]

#todo[Are qualifiers specific to an RDF implementation?]


=== SPARQL Protocol and RDF Query Language <sparql_heading>

#blockquote[
  SPARQL can be used to express queries across diverse data sources, whether the data is stored natively as RDF or viewed as RDF via middleware. SPARQL contains capabilities for querying required and optional graph patterns along with their conjunctions and disjunctions. SPARQL also supports extensible value testing and constraining queries by source RDF graph. The results of SPARQL queries can be results sets or RDF graphs. @W3C_SPARQL_Specification
]

#todo[
  Which features does SPARQL offer?

  - How does "describe" work? (because it might be interesting as a graph exploring method)
]

== Visual Query Graph
This chapter mostly follows @Vargas2019_RDF_Explorer. 

#definition[
  A visual query graph (VQG) is defined as a directed, edge-labelled graph $G=(V,E)$, with vertices $V$ and edges $E$. The vertices of $G$ are a finite set of IRIs, literals or variables: $N subset bold("I") union bold("L") union bold("V")$.
  The edges of the VQG are a finite set of triples, where each triple indicated a directed edge between two nodes with a label taken from the set of IRIs or variables: $E subset N times (bold("I") union bold("V")) times N$.
  Note here, that the VQG does not contain blank nodes.
]

The VQG is _constructed_ using a _visual query language_, consisting of four algebraic operators, which will correspond to atomic user interactions:

#figure(
  table(columns: 2,
    [User Interaction], [Inverse User Action],
    [Adding a variable node], [Removing a node],
    [Adding a literal node], [Removing a node],
    [Adding a directed edge], [Removing a directed edge],
  )
)


== Linked Open Data <heading_lod>

== Web Ontology Language <heading_owl>
@Sack2009_OWL_und_OWL_Semantik
@Lacy2005_OWL

= Developed architecture / system design / implementation

#todo[
Should contain the following aspects:
- start with a theoretical approach
- describe the developed system/algorithm/method from a high-level point of view
- go ahead in presenting your developments in more detail
]

== Architecture
- Web App (Vite+Vue+Rust+ReteJS+TailwindCSS)
- All mapping algorithms are written in Rust to ensure completeness and speed
- Integrates fuzzy search using Wikibase APIs (exemplary implementation for Wikidata and FactGrid)

== Visual Query Graph-SPARQL Mapping
Novel to current work:
+ Qualifiers are visualised more intuitively (see Simons Blog @Simons_Blog_Entry_Graphic_query)
+ Multiple data sources and clear prefixes #todo[Check, whether this is actually new]
+ ... more?

== SPARQL-OWL Mapping

=== Select Queries
#todo[
  Which features can I graphically visualise?
  - Triples
  - Qualifiers
  - Literals
  - blank nodes?
  - Filters?
  - ...
]

A SPARQL-SELECT-Query

= Measurement results / analysis / discussion

#todo[
- whatever you have done, you must comment it, compare it to other systems, evaluate it
- usually, adequate graphs help to show the benefits of your approach
- caution: each result/graph must be discussed! what’s the reason for this peak or why have you observed this effect
]

== Practical Application
- Patrick Stahl developed for Clemens Beck
- Changes / contributions by patrick are clearly marked in Version Control

#todo[How do I license the code? Maybe Rechtsamt fragen.]

= Further Work

+ Creating SPARQL assertions (INSERT statement)

+ SPARQL FILTER query

+ Allow user to specify own data sources

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
