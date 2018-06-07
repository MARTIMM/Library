#!/usr/bin/env perl6

use v6;

#-------------------------------------------------------------------------------
# Read a list of file extensions amd their mimetype and store in database
# lines like
#   .mid audio/midi
#   .midi audio/midi
#   .kar audio/midi
# must be converted into documents like
#   _id => audio-midi
#   type => audio
#   subtype => midi
#   ext => [
#     .mid, .midi, .kar
#   ]
#
# and several others like
#   _id => .mid
#   mimetype_id => audio-midi
# ...

use MongoDB;
use MongoDB::Client;
use MongoDB::Database;

use BSON::Document;

use Library;
use Library::Configuration;

#-------------------------------------------------------------------------------
# Program to store the data in MongoDB Library. First get connection,
# database and collection. Drop the old collection before filling.
#-------------------------------------------------------------------------------
sub MAIN ( ) {

  my Str $lib-dir = %*ENV<LIBRARY_CONFIG> // $*HOME.Str ~ '/.library';
  initialize-library;

  my Library::Configuration $cfg = $Library::lib-cfg;
  my MongoDB::Client $client = $Library::client;

  my Str $db-name = $cfg.database-name(:root);
  my Str $cl-name = $cfg.collection-name( 'mimetypes', :root);
  my MongoDB::Database $database = $client.database($db-name);
  my MongoDB::Collection $collection = $database.collection($cl-name);

  # gather data into hash
  my Hash $mt-hash = {};

  # Get the list from comment pod-block and store in a hash
  my Str $content = get-data('linux-mimetypes');
  for $content.split("\n") -> $line {

    my Str $ext;
    my Str $mimetype;
    my Str $mt-type;
    my Str $mt-subtype;
    my @line-items = $line.split(/\s+/);
    $mimetype = @line-items.shift;
    ( $mt-type, $mt-subtype) = $mimetype.split(/\//);

    my Str $id = $mt-type ~ '-' ~ $mt-subtype;
    $mt-hash{$id} = {};
    $mt-hash{$id}<type> = $mt-type;
    $mt-hash{$id}<subtype> = $mt-subtype;
    $mt-hash{$id}<ext> = [];

#note "$id, $mimetype, $mt-type, $mt-subtype, {@line-items.join(', ')}";
    if +@line-items {
      # add a dot before extension to prevent clashes with type-subtype id
      $mt-hash{$id}<ext>.push: |@line-items>>.fmt(".%s");
    }
#note "E: {$mt-hash{$id}<ext>.join(', ')}";
  }

  # rearrange all to store documents in the collection
  for $mt-hash.keys.sort -> $id {
    my Array $documents = [];

    # document store with key on type_subtype
    $documents.push( BSON::Document.new( (
          :_id($id),
          :type($mt-hash{$id}<type>),
          :subtype($mt-hash{$id}<subtype>),
          :ext($mt-hash{$id}<ext>),
        )
      )
    );

    for @($mt-hash{$id}<ext>) -> $ext {
      # documents store with key on extension
      $documents.push( BSON::Document.new( (
            :_id($ext),
            :mimetype_id($id),
          )
        )
      );
    }

#note "DB: ", $database.perl;
    my BSON::Document $result-doc = $database.run-command: (
      :insert($cl-name), :$documents,
    );

    if $result-doc<ok> ~~ 1e0 {
      info-message(
        "mimetype id '$id' stored and {+$documents -1} extension docs"
      );
    }

    else {
      warn-message("duplicate key, mimetype id '$id' is stored before");
note "Fail result: ", $result-doc.perl;
    }
  }
}

#-------------------------------------------------------------------------------
sub get-data ( Str:D $content-key --> Str ) {

  my Str $content;
  for @$=pod -> $pd {
    if $pd ~~ Pod::Block::Comment and
       !$pd.config<comment> and
       $pd.config<type> eq $content-key {

#.say for @($pd.contents.lines);
      $content = $pd.contents[0];
      last;
    }
  }

  # remove comments
  $content ~~ s:g/\s* '#' .*? $$//;

  # remove empty lines
  $content ~~ s:g/^^ \s* $$//;
  $content ~~ s:g/\n\n+/\n/;
  $content ~~ s:g/^\n+//;
  $content ~~ s:g/\n+$//;
#say $content;
#exit;
  $content
}

#-------------------------------------------------------------------------------
# linux mimetypes list /etc/mime.types
=begin comment :!comment :type<linux-mimetypes>

application/1d-interleaved-parityfec
application/3gpdash-qoe-report+xml
application/3gpp-ims+xml
application/A2L					a2l
application/activemessage
application/alto-costmap+json
application/alto-costmapfilter+json
application/alto-directory+json
application/alto-endpointcost+json
application/alto-endpointcostparams+json
application/alto-endpointprop+json
application/alto-endpointpropparams+json
application/alto-error+json
application/alto-networkmap+json
application/alto-networkmapfilter+json
application/AML					aml
application/andrew-inset			ez
application/applefile
application/ATF					atf
application/ATFX				atfx
application/ATXML				atxml
application/atom+xml				atom
application/atomcat+xml				atomcat
application/atomdeleted+xml			atomdeleted
application/atomicmail
application/atomsvc+xml				atomsvc
application/auth-policy+xml			apxml
application/bacnet-xdd+zip			xdd
application/batch-SMTP
application/beep+xml
application/calendar+json
application/calendar+xml			xcs
application/call-completion
application/cals-1840
application/cbor				cbor
application/ccmp+xml				ccmp
application/ccxml+xml				ccxml
application/CDFX+XML				cdfx
application/cdmi-capability			cdmia
application/cdmi-container			cdmic
application/cdmi-domain				cdmid
application/cdmi-object				cdmio
application/cdmi-queue				cdmiq
application/cdni
application/CEA					cea
application/cea-2018+xml
application/cellml+xml				cellml cml
application/cfw
application/clue_info+xml			clue
application/cms					cmsc
application/cnrp+xml
application/coap-group+json
application/coap-payload
application/commonground
application/conference-info+xml
application/cpl+xml				cpl
application/cose
application/cose-key
application/cose-key-set
application/csrattrs				csrattrs
application/csta+xml
application/CSTAdata+xml
application/csvm+json
application/cybercash
application/dash+xml				mpd
application/dashdelta				mpdd
application/davmount+xml			davmount
application/dca-rft
application/DCD					dcd
application/dec-dx
application/dialog-info+xml
application/dicom				dcm
application/dicom+json
application/dicom+xml
application/DII					dii
application/DIT					dit
application/dns
application/dskpp+xml				xmls
application/dssc+der				dssc
application/dssc+xml				xdssc
application/dvcs				dvc
application/ecmascript				es
application/EDI-Consent
application/EDI-X12
application/EDIFACT
application/efi					efi
application/EmergencyCallData.Comment+xml
application/EmergencyCallData.Control+xml
application/EmergencyCallData.DeviceInfo+xml
application/EmergencyCallData.eCall.MSD
application/EmergencyCallData.ProviderInfo+xml
application/EmergencyCallData.ServiceInfo+xml
application/EmergencyCallData.SubscriberInfo+xml
application/EmergencyCallData.VEDS+xml
application/emma+xml				emma
application/emotionml+xml			emotionml
application/encaprtp
application/epp+xml
application/epub+zip				epub
application/eshop
application/exi					exi
application/fastinfoset				finf
application/fastsoap
application/fdt+xml				fdt
# fits, fit, fts: image/fits
application/fits
# application/font-sfnt deprecated in favor of font/sfnt
application/font-tdpfr				pfr
# application/font-woff deprecated in favor of font/woff
application/framework-attributes+xml
application/geo+json				geojson
application/geo+json-seq
application/gml+xml				gml
application/gzip				gz tgz
application/H224
application/held+xml
application/http
application/hyperstudio				stk
application/ibe-key-request+xml
application/ibe-pkg-reply+xml
application/ibe-pp-data
application/iges
application/im-iscomposing+xml
application/index
application/index.cmd
application/index.obj
application/index.response
application/index.vnd
application/inkml+xml				ink inkml
application/iotp
application/ipfix				ipfix
application/ipp
application/isup
application/its+xml				its
application/javascript				js
application/jose
application/jose+json
application/jrd+json				jrd
application/json				json
application/json-patch+json			json-patch
application/json-seq
application/jwk+json
application/jwk-set+json
application/jwt
application/kpml-request+xml
application/kpml-response+xml
application/ld+json				jsonld
application/lgr+xml				lgr
application/link-format				wlnk
application/load-control+xml
application/lost+xml				lostxml
application/lostsync+xml			lostsyncxml
application/LXF					lxf
application/mac-binhex40			hqx
application/macwriteii
application/mads+xml				mads
application/marc				mrc
application/marcxml+xml				mrcx
application/mathematica				nb ma mb
application/mathml-content+xml
application/mathml-presentation+xml
application/mathml+xml				mml
application/mbms-associated-procedure-description+xml
application/mbms-deregister+xml
application/mbms-envelope+xml
application/mbms-msk-response+xml
application/mbms-msk+xml
application/mbms-protection-description+xml
application/mbms-reception-report+xml
application/mbms-register-response+xml
application/mbms-register+xml
application/mbms-schedule+xml
application/mbms-user-service-description+xml
application/mbox				mbox
application/media_control+xml
# mpf: text/vnd.ms-mediapackage
application/media-policy-dataset+xml
application/mediaservercontrol+xml
application/merge-patch+json
application/metalink4+xml			meta4
application/mets+xml				mets
application/MF4					mf4
application/mikey
application/mods+xml				mods
application/moss-keys
application/moss-signature
application/mosskey-data
application/mosskey-request
application/mp21				m21 mp21
# mp4, mpg4: video/mp4, see RFC 4337
application/mp4
application/mpeg4-generic
application/mpeg4-iod
application/mpeg4-iod-xmt
# xdf: application/xcap-diff+xml
application/mrb-consumer+xml
application/mrb-publish+xml
application/msc-ivr+xml
application/msc-mixer+xml
application/msword				doc
application/mud+json
application/mxf					mxf
application/n-quads				nq
application/n-triples				nt
application/nasdata
application/news-checkgroups
application/news-groupinfo
application/news-transmission
application/nlsml+xml
application/nss
application/ocsp-request			orq
application/ocsp-response			ors
application/octet-stream		bin lha lzh exe class so dll img iso
application/oda					oda
application/ODX					odx
application/oebps-package+xml			opf
application/ogg					ogx
application/oxps				oxps
application/p2p-overlay+xml			relo
application/parityfec
# xer: application/xcap-error+xml
application/patch-ops-error+xml
application/pdf					pdf
application/PDX					pdx
application/pgp-encrypted			pgp
application/pgp-keys
application/pgp-signature			sig
application/pidf-diff+xml
application/pidf+xml
application/pkcs10				p10
application/pkcs12				p12 pfx
application/pkcs7-mime				p7m p7c
application/pkcs7-signature			p7s
application/pkcs8				p8
# ac: application/vnd.nokia.n-gage.ac+xml
application/pkix-attr-cert
application/pkix-cert				cer
application/pkix-crl				crl
application/pkix-pkipath			pkipath
application/pkixcmp				pki
application/pls+xml				pls
application/poc-settings+xml
application/postscript				ps eps ai
application/ppsp-tracker+json
application/problem+json
application/problem+xml
application/provenance+xml			provx
application/prs.alvestrand.titrax-sheet
application/prs.cww				cw cww
application/prs.hpub+zip			hpub
application/prs.nprend				rnd rct
application/prs.plucker
application/prs.rdf-xml-crypt			rdf-crypt
application/prs.xsf+xml				xsf
application/pskc+xml				pskcxml
application/qsig
application/raptorfec
application/rdap+json
application/rdf+xml				rdf
application/reginfo+xml				rif
application/relax-ng-compact-syntax		rnc
application/remote-printing
application/reputon+json
application/resource-lists-diff+xml		rld
application/resource-lists+xml			rl
application/rfc+xml				rfcxml
application/riscos
application/rlmi+xml
application/rls-services+xml			rs
application/rpki-ghostbusters			gbr
application/rpki-manifest			mft
application/rpki-publication
application/rpki-roa				roa
application/rpki-updown
application/rtf					rtf
application/rtploopback
application/rtx
application/samlassertion+xml
application/samlmetadata+xml
application/sbml+xml
application/scaip+xml
# scm: application/vnd.lotus-screencam
application/scim+json				scim
application/scvp-cv-request			scq
application/scvp-cv-response			scs
application/scvp-vp-request			spq
application/scvp-vp-response			spp
application/sdp					sdp
application/sep+xml
application/sep-exi
application/session-info
application/set-payment
application/set-payment-initiation
application/set-registration
application/set-registration-initiation
application/sgml
application/sgml-open-catalog			soc
application/shf+xml				shf
application/sieve				siv sieve
application/simple-filter+xml			cl
application/simple-message-summary
application/simpleSymbolContainer
application/slate
# application/smil obsoleted by application/smil+xml
application/smil+xml				smil smi sml
application/smpte336m
application/soap+fastinfoset
application/soap+xml
application/sparql-query			rq
application/sparql-results+xml			srx
application/spirits-event+xml
application/sql					sql
application/srgs				gram
application/srgs+xml				grxml
application/sru+xml				sru
application/ssml+xml				ssml
application/tamp-apex-update			tau
application/tamp-apex-update-confirm		auc
application/tamp-community-update		tcu
application/tamp-community-update-confirm	cuc
application/tamp-error				ter
application/tamp-sequence-adjust		tsa
application/tamp-sequence-adjust-confirm	sac
# tsq: application/timestamp-query
application/tamp-status-query
# tsr: application/timestamp-reply
application/tamp-status-response
application/tamp-update				tur
application/tamp-update-confirm			tuc
application/tei+xml				tei teiCorpus odd
application/thraud+xml				tfi
application/timestamp-query			tsq
application/timestamp-reply			tsr
application/timestamped-data			tsd
application/trig				trig
application/ttml+xml				ttml
application/tve-trigger
application/ulpfec
application/urc-grpsheet+xml			gsheet
application/urc-ressheet+xml			rsheet
application/urc-targetdesc+xml			td
application/urc-uisocketdesc+xml		uis
application/vcard+json
application/vcard+xml
application/vemmi
application/vnd.3gpp.access-transfer-events+xml
application/vnd.3gpp.bsf+xml
application/vnd.3gpp.mid-call+xml
application/vnd.3gpp.pic-bw-large		plb
application/vnd.3gpp.pic-bw-small		psb
application/vnd.3gpp.pic-bw-var			pvb
application/vnd.3gpp-prose+xml
application/vnd.3gpp-prose-pc3ch+xml
# sms: application/vnd.3gpp2.sms
application/vnd.3gpp.sms
application/vnd.3gpp.sms+xml
application/vnd.3gpp.srvcc-ext+xml
application/vnd.3gpp.SRVCC-info+xml
application/vnd.3gpp.state-and-event-info+xml
application/vnd.3gpp.ussd+xml
application/vnd.3gpp2.bcmcsinfo+xml
application/vnd.3gpp2.sms			sms
application/vnd.3gpp2.tcap			tcap
application/vnd.3lightssoftware.imagescal	imgcal
application/vnd.3M.Post-it-Notes		pwn
application/vnd.accpac.simply.aso		aso
application/vnd.accpac.simply.imp		imp
application/vnd.acucobol			acu
application/vnd.acucorp				atc acutc
application/vnd.adobe.flash.movie		swf
application/vnd.adobe.formscentral.fcdt		fcdt
application/vnd.adobe.fxp			fxp fxpl
application/vnd.adobe.partial-upload
application/vnd.adobe.xdp+xml			xdp
application/vnd.adobe.xfdf			xfdf
application/vnd.aether.imp
application/vnd.ah-barcode
application/vnd.ahead.space			ahead
application/vnd.airzip.filesecure.azf		azf
application/vnd.airzip.filesecure.azs		azs
application/vnd.amazon.mobi8-ebook		azw3
application/vnd.americandynamics.acc		acc
application/vnd.amiga.ami			ami
application/vnd.amundsen.maze+xml
application/vnd.anki				apkg
application/vnd.anser-web-certificate-issue-initiation	cii
# Not in IANA listing, but is on FTP site?
application/vnd.anser-web-funds-transfer-initiation	fti
# atx: audio/ATRAC-X
application/vnd.antix.game-component
application/vnd.apache.thrift.binary
application/vnd.apache.thrift.compact
application/vnd.apache.thrift.json
application/vnd.api+json
application/vnd.apothekende.reservation+json
application/vnd.apple.installer+xml		dist distz pkg mpkg
# m3u: audio/x-mpegurl for now
application/vnd.apple.mpegurl			m3u8
# application/vnd.arastra.swi obsoleted by application/vnd.aristanetworks.swi
application/vnd.aristanetworks.swi		swi
application/vnd.artsquare
application/vnd.astraea-software.iota		iota
application/vnd.audiograph			aep
application/vnd.autopackage			package
application/vnd.avistar+xml
application/vnd.balsamiq.bmml+xml		bmml
application/vnd.balsamiq.bmpr			bmpr
application/vnd.bekitzur-stech+json
application/vnd.bint.med-content
application/vnd.biopax.rdf+xml
application/vnd.blueice.multipass		mpm
application/vnd.bluetooth.ep.oob		ep
application/vnd.bluetooth.le.oob		le
application/vnd.bmi				bmi
application/vnd.businessobjects			rep
application/vnd.cab-jscript
application/vnd.canon-cpdl
application/vnd.canon-lips
application/vnd.capasystems-pg+json
application/vnd.cendio.thinlinc.clientconf	tlclient
application/vnd.century-systems.tcp_stream
application/vnd.chemdraw+xml			cdxml
application/vnd.chess-pgn			pgn
application/vnd.chipnuts.karaoke-mmd		mmd
application/vnd.cinderella			cdy
application/vnd.cirpack.isdn-ext
application/vnd.citationstyles.style+xml	csl
application/vnd.claymore			cla
application/vnd.cloanto.rp9			rp9
application/vnd.clonk.c4group			c4g c4d c4f c4p c4u
application/vnd.cluetrust.cartomobile-config	c11amc
application/vnd.cluetrust.cartomobile-config-pkg	c11amz
application/vnd.coffeescript			coffee
application/vnd.collection+json
application/vnd.collection.doc+json
application/vnd.collection.next+json
application/vnd.comicbook+zip			cbz
# icc: application/vnd.iccprofile
application/vnd.commerce-battelle	ica icf icd ic0 ic1 ic2 ic3 ic4 ic5 ic6 ic7 ic8
application/vnd.commonspace			csp cst
application/vnd.contact.cmsg			cdbcmsg
application/vnd.coreos.ignition+json		ign ignition
application/vnd.cosmocaller			cmc
application/vnd.crick.clicker			clkx
application/vnd.crick.clicker.keyboard		clkk
application/vnd.crick.clicker.palette		clkp
application/vnd.crick.clicker.template		clkt
application/vnd.crick.clicker.wordbank		clkw
application/vnd.criticaltools.wbs+xml		wbs
application/vnd.ctc-posml			pml
application/vnd.ctct.ws+xml
application/vnd.cups-pdf
application/vnd.cups-postscript
application/vnd.cups-ppd			ppd
application/vnd.cups-raster
application/vnd.cups-raw
application/vnd.curl				curl
application/vnd.cyan.dean.root+xml
application/vnd.cybank
application/vnd.d2l.coursepackage1p0+zip
application/vnd.dart				dart
application/vnd.data-vision.rdz			rdz
application/vnd.datapackage+json
application/vnd.dataresource+json
application/vnd.debian.binary-package		deb udeb
application/vnd.dece.data			uvf uvvf uvd uvvd
application/vnd.dece.ttml+xml			uvt uvvt
application/vnd.dece.unspecified		uvx uvvx
application/vnd.dece.zip			uvz uvvz
application/vnd.denovo.fcselayout-link		fe_launch
application/vnd.desmume.movie			dsm
application/vnd.dir-bi.plate-dl-nosuffix
application/vnd.dm.delegation+xml
application/vnd.dna				dna
application/vnd.document+json			docjson
application/vnd.dolby.mobile.1
application/vnd.dolby.mobile.2
application/vnd.doremir.scorecloud-binary-document	scld
application/vnd.dpgraph				dpg mwc dpgraph
application/vnd.dreamfactory			dfac
application/vnd.drive+json
application/vnd.dtg.local
application/vnd.dtg.local.flash			fla
application/vnd.dtg.local.html
application/vnd.dvb.ait				ait
# class: application/octet-stream
application/vnd.dvb.dvbj
application/vnd.dvb.esgcontainer
application/vnd.dvb.ipdcdftnotifaccess
application/vnd.dvb.ipdcesgaccess
application/vnd.dvb.ipdcesgaccess2
application/vnd.dvb.ipdcesgpdd
application/vnd.dvb.ipdcroaming
application/vnd.dvb.iptv.alfec-base
application/vnd.dvb.iptv.alfec-enhancement
application/vnd.dvb.notif-aggregate-root+xml
application/vnd.dvb.notif-container+xml
application/vnd.dvb.notif-generic+xml
application/vnd.dvb.notif-ia-msglist+xml
application/vnd.dvb.notif-ia-registration-request+xml
application/vnd.dvb.notif-ia-registration-response+xml
application/vnd.dvb.notif-init+xml
# pfr: application/font-tdpfr
application/vnd.dvb.pfr
application/vnd.dvb.service			svc
# dxr: application/x-director
application/vnd.dxr
application/vnd.dynageo				geo
application/vnd.dzr				dzr
application/vnd.easykaraoke.cdgdownload
application/vnd.ecdis-update
application/vnd.ecowin.chart			mag
application/vnd.ecowin.filerequest
application/vnd.ecowin.fileupdate
application/vnd.ecowin.series
application/vnd.ecowin.seriesrequest
application/vnd.ecowin.seriesupdate
# img: application/octet-stream
application/vnd.efi-img
# iso: application/octet-stream
application/vnd.efi-iso
application/vnd.enliven				nml
application/vnd.enphase.envoy
application/vnd.eprints.data+xml
application/vnd.epson.esf			esf
application/vnd.epson.msf			msf
application/vnd.epson.quickanime		qam
application/vnd.epson.salt			slt
application/vnd.epson.ssf			ssf
application/vnd.ericsson.quickcall		qcall qca
application/vnd.espass-espass+zip		espass
application/vnd.eszigno3+xml			es3 et3
application/vnd.etsi.aoc+xml
application/vnd.etsi.asic-e+zip			asice sce
# scs: application/scvp-cv-response
application/vnd.etsi.asic-s+zip			asics
application/vnd.etsi.cug+xml
application/vnd.etsi.iptvcommand+xml
application/vnd.etsi.iptvdiscovery+xml
application/vnd.etsi.iptvprofile+xml
application/vnd.etsi.iptvsad-bc+xml
application/vnd.etsi.iptvsad-cod+xml
application/vnd.etsi.iptvsad-npvr+xml
application/vnd.etsi.iptvservice+xml
application/vnd.etsi.iptvsync+xml
application/vnd.etsi.iptvueprofile+xml
application/vnd.etsi.mcid+xml
application/vnd.etsi.mheg5
application/vnd.etsi.overload-control-policy-dataset+xml
application/vnd.etsi.pstn+xml
application/vnd.etsi.sci+xml
application/vnd.etsi.simservs+xml
application/vnd.etsi.timestamp-token		tst
application/vnd.etsi.tsl.der
application/vnd.etsi.tsl+xml
application/vnd.eudora.data
application/vnd.ezpix-album			ez2
application/vnd.ezpix-package			ez3
application/vnd.f-secure.mobile
application/vnd.fastcopy-disk-image		dim
application/vnd.fdf				fdf
application/vnd.fdsn.mseed			msd mseed
application/vnd.fdsn.seed			seed dataless
application/vnd.ffsns
application/vnd.filmit.zfc			zfc
# all extensions: application/vnd.hbci
application/vnd.fints
application/vnd.firemonkeys.cloudcell
application/vnd.FloGraphIt			gph
application/vnd.fluxtime.clip			ftc
application/vnd.font-fontforge-sfd		sfd
application/vnd.framemaker			fm
application/vnd.frogans.fnc			fnc
application/vnd.frogans.ltf			ltf
application/vnd.fsc.weblaunch			fsc
application/vnd.fujitsu.oasys			oas
application/vnd.fujitsu.oasys2			oa2
application/vnd.fujitsu.oasys3			oa3
application/vnd.fujitsu.oasysgp			fg5
application/vnd.fujitsu.oasysprs		bh2
application/vnd.fujixerox.ART-EX
application/vnd.fujixerox.ART4
application/vnd.fujixerox.ddd			ddd
application/vnd.fujixerox.docuworks		xdw
application/vnd.fujixerox.docuworks.binder	xbd
application/vnd.fujixerox.docuworks.container	xct
application/vnd.fujixerox.HBPL
application/vnd.fut-misnet
application/vnd.fuzzysheet			fzs
application/vnd.genomatix.tuxedo		txd
# application/vnd.geo+json obsoleted by application/geo+json
application/vnd.geocube+xml			g3 gÂ³
application/vnd.geogebra.file			ggb
application/vnd.geogebra.tool			ggt
application/vnd.geometry-explorer		gex gre
application/vnd.geonext				gxt
application/vnd.geoplan				g2w
application/vnd.geospace			g3w
# gbr: application/rpki-ghostbusters
application/vnd.gerber
application/vnd.globalplatform.card-content-mgt
application/vnd.globalplatform.card-content-mgt-response
application/vnd.gmx				gmx
application/vnd.google-earth.kml+xml		kml
application/vnd.google-earth.kmz		kmz
application/vnd.gov.sk.e-form+xml
application/vnd.gov.sk.e-form+zip
application/vnd.gov.sk.xmldatacontainer+xml
application/vnd.grafeq				gqf gqs
application/vnd.gridmp
application/vnd.groove-account			gac
application/vnd.groove-help			ghf
application/vnd.groove-identity-message		gim
application/vnd.groove-injector			grv
application/vnd.groove-tool-message		gtm
application/vnd.groove-tool-template		tpl
application/vnd.groove-vcard			vcg
application/vnd.hal+json
application/vnd.hal+xml				hal
application/vnd.HandHeld-Entertainment+xml	zmm
application/vnd.hbci				hbci hbc kom upa pkd bpd
application/vnd.hc+json
# rep: application/vnd.businessobjects
application/vnd.hcl-bireports
application/vnd.hdt				hdt
application/vnd.heroku+json
application/vnd.hhe.lesson-player		les
application/vnd.hp-HPGL				hpgl
application/vnd.hp-hpid				hpi hpid
application/vnd.hp-hps				hps
application/vnd.hp-jlyt				jlt
application/vnd.hp-PCL				pcl
application/vnd.hp-PCLXL
application/vnd.httphone
application/vnd.hydrostatix.sof-data		sfd-hdstx
application/vnd.hyperdrive+json
application/vnd.hzn-3d-crossword		x3d
application/vnd.ibm.afplinedata
application/vnd.ibm.electronic-media		emm
application/vnd.ibm.MiniPay			mpy
application/vnd.ibm.modcap			list3820 listafp afp pseg3820
application/vnd.ibm.rights-management		irm
application/vnd.ibm.secure-container		sc
application/vnd.iccprofile			icc icm
application/vnd.ieee.1905			1905.1
application/vnd.igloader			igl
application/vnd.imagemeter.folder+zip		imf
application/vnd.imagemeter.image+zip		imi
application/vnd.immervision-ivp			ivp
application/vnd.immervision-ivu			ivu
application/vnd.ims.imsccv1p1			imscc
application/vnd.ims.imsccv1p2
application/vnd.ims.imsccv1p3
application/vnd.ims.lis.v2.result+json
application/vnd.ims.lti.v2.toolconsumerprofile+json
application/vnd.ims.lti.v2.toolproxy.id+json
application/vnd.ims.lti.v2.toolproxy+json
application/vnd.ims.lti.v2.toolsettings+json
application/vnd.ims.lti.v2.toolsettings.simple+json
application/vnd.informedcontrol.rms+xml
# application/vnd.informix-visionary obsoleted by application/vnd.visionary
application/vnd.infotech.project
application/vnd.infotech.project+xml
application/vnd.innopath.wamp.notification
application/vnd.insors.igm			igm
application/vnd.intercon.formnet		xpw xpx
application/vnd.intergeo			i2g
application/vnd.intertrust.digibox
application/vnd.intertrust.nncp
application/vnd.intu.qbo			qbo
application/vnd.intu.qfx			qfx
application/vnd.iptc.g2.catalogitem+xml
application/vnd.iptc.g2.conceptitem+xml
application/vnd.iptc.g2.knowledgeitem+xml
application/vnd.iptc.g2.newsitem+xml
application/vnd.iptc.g2.newsmessage+xml
application/vnd.iptc.g2.packageitem+xml
application/vnd.iptc.g2.planningitem+xml
application/vnd.ipunplugged.rcprofile		rcprofile
application/vnd.irepository.package+xml		irp
application/vnd.is-xpr				xpr
application/vnd.isac.fcs			fcs
application/vnd.jam				jam
application/vnd.japannet-directory-service
application/vnd.japannet-jpnstore-wakeup
application/vnd.japannet-payment-wakeup
application/vnd.japannet-registration
application/vnd.japannet-registration-wakeup
application/vnd.japannet-setstore-wakeup
application/vnd.japannet-verification
application/vnd.japannet-verification-wakeup
application/vnd.jcp.javame.midlet-rms		rms
application/vnd.jisp				jisp
application/vnd.joost.joda-archive		joda
application/vnd.jsk.isdn-ngn
application/vnd.kahootz				ktz ktr
application/vnd.kde.karbon			karbon
application/vnd.kde.kchart			chrt
application/vnd.kde.kformula			kfo
application/vnd.kde.kivio			flw
application/vnd.kde.kontour			kon
application/vnd.kde.kpresenter			kpr kpt
application/vnd.kde.kspread			ksp
application/vnd.kde.kword			kwd kwt
application/vnd.kenameaapp			htke
application/vnd.kidspiration			kia
application/vnd.Kinar				kne knp sdf
application/vnd.koan				skp skd skm skt
application/vnd.kodak-descriptor		sse
application/vnd.las.las+json			lasjson
application/vnd.las.las+xml			lasxml
application/vnd.liberty-request+xml
application/vnd.llamagraphics.life-balance.desktop	lbd
application/vnd.llamagraphics.life-balance.exchange+xml	lbe
application/vnd.lotus-1-2-3			123 wk4 wk3 wk1
application/vnd.lotus-approach			apr vew
application/vnd.lotus-freelance			prz pre
application/vnd.lotus-notes			nsf ntf ndl ns4 ns3 ns2 nsh nsg
application/vnd.lotus-organizer			or3 or2 org
application/vnd.lotus-screencam			scm
application/vnd.lotus-wordpro			lwp sam
application/vnd.macports.portpkg		portpkg
application/vnd.mapbox-vector-tile		mvt
application/vnd.marlin.drm.actiontoken+xml
application/vnd.marlin.drm.conftoken+xml
application/vnd.marlin.drm.license+xml
application/vnd.marlin.drm.mdcf			mdc
application/vnd.mason+json
application/vnd.maxmind.maxmind-db		mmdb
application/vnd.mcd				mcd
application/vnd.medcalcdata			mc1
application/vnd.mediastation.cdkey		cdkey
application/vnd.meridian-slingshot
application/vnd.MFER				mwf
application/vnd.mfmp				mfm
application/vnd.micro+json
application/vnd.micrografx.flo			flo
application/vnd.micrografx.igx			igx
application/vnd.microsoft.portable-executable
application/vnd.microsoft.windows.thumbnail-cache
application/vnd.miele+json
application/vnd.mif				mif
application/vnd.minisoft-hp3000-save
application/vnd.mitsubishi.misty-guard.trustweb
application/vnd.Mobius.DAF			daf
application/vnd.Mobius.DIS			dis
application/vnd.Mobius.MBK			mbk
application/vnd.Mobius.MQY			mqy
application/vnd.Mobius.MSL			msl
application/vnd.Mobius.PLC			plc
application/vnd.Mobius.TXF			txf
application/vnd.mophun.application		mpn
application/vnd.mophun.certificate		mpc
application/vnd.motorola.flexsuite
application/vnd.motorola.flexsuite.adsi
application/vnd.motorola.flexsuite.fis
application/vnd.motorola.flexsuite.gotap
application/vnd.motorola.flexsuite.kmr
application/vnd.motorola.flexsuite.ttc
application/vnd.motorola.flexsuite.wem
application/vnd.motorola.iprm
application/vnd.mozilla.xul+xml			xul
application/vnd.ms-3mfdocument			3mf
application/vnd.ms-artgalry			cil
application/vnd.ms-asf				asf
application/vnd.ms-cab-compressed		cab
application/vnd.ms-excel			xls xlm xla xlc xlt xlw
application/vnd.ms-excel.template.macroEnabled.12	xltm
application/vnd.ms-excel.addin.macroEnabled.12	xlam
application/vnd.ms-excel.sheet.binary.macroEnabled.12	xlsb
application/vnd.ms-excel.sheet.macroEnabled.12	xlsm
application/vnd.ms-fontobject			eot
application/vnd.ms-htmlhelp			chm
application/vnd.ms-ims				ims
application/vnd.ms-lrm				lrm
application/vnd.ms-office.activeX+xml
application/vnd.ms-officetheme			thmx
application/vnd.ms-playready.initiator+xml
application/vnd.ms-powerpoint			ppt pps pot
application/vnd.ms-powerpoint.addin.macroEnabled.12	ppam
application/vnd.ms-powerpoint.presentation.macroEnabled.12	pptm
application/vnd.ms-powerpoint.slide.macroEnabled.12	sldm
application/vnd.ms-powerpoint.slideshow.macroEnabled.12	ppsm
application/vnd.ms-powerpoint.template.macroEnabled.12	potm
application/vnd.ms-PrintDeviceCapabilities+xml
application/vnd.ms-PrintSchemaTicket+xml
application/vnd.ms-project			mpp mpt
application/vnd.ms-tnef				tnef tnf
application/vnd.ms-windows.devicepairing
application/vnd.ms-windows.nwprinting.oob
application/vnd.ms-windows.printerpairing
application/vnd.ms-windows.wsd.oob
application/vnd.ms-wmdrm.lic-chlg-req
application/vnd.ms-wmdrm.lic-resp
application/vnd.ms-wmdrm.meter-chlg-req
application/vnd.ms-wmdrm.meter-resp
application/vnd.ms-word.document.macroEnabled.12	docm
application/vnd.ms-word.template.macroEnabled.12	dotm
application/vnd.ms-works			wcm wdb wks wps
application/vnd.ms-wpl				wpl
application/vnd.ms-xpsdocument			xps
application/vnd.msa-disk-image			msa
application/vnd.mseq				mseq
application/vnd.msign
application/vnd.multiad.creator			crtr
application/vnd.multiad.creator.cif		cif
application/vnd.music-niff
application/vnd.musician			mus
application/vnd.muvee.style			msty
application/vnd.mynfc				taglet
application/vnd.ncd.control
application/vnd.ncd.reference
application/vnd.nearst.inv+json
application/vnd.nervana				entity request bkm kcm
application/vnd.netfpx
# ntf: application/vnd.lotus-notes
application/vnd.nitf				nitf
application/vnd.neurolanguage.nlu		nlu
application/vnd.nintendo.nitro.rom		nds
application/vnd.nintendo.snes.rom		sfc smc
application/vnd.noblenet-directory		nnd
application/vnd.noblenet-sealer			nns
application/vnd.noblenet-web			nnw
application/vnd.nokia.catalogs
application/vnd.nokia.conml+wbxml
application/vnd.nokia.conml+xml
application/vnd.nokia.iptv.config+xml
application/vnd.nokia.iSDS-radio-presets
application/vnd.nokia.landmark+wbxml
application/vnd.nokia.landmark+xml
application/vnd.nokia.landmarkcollection+xml
application/vnd.nokia.n-gage.ac+xml		ac
application/vnd.nokia.n-gage.data		ngdat
application/vnd.nokia.n-gage.symbian.install	n-gage
application/vnd.nokia.ncd
application/vnd.nokia.pcd+wbxml
application/vnd.nokia.pcd+xml
application/vnd.nokia.radio-preset		rpst
application/vnd.nokia.radio-presets		rpss
application/vnd.novadigm.EDM			edm
application/vnd.novadigm.EDX			edx
application/vnd.novadigm.EXT			ext
application/vnd.ntt-local.content-share
application/vnd.ntt-local.file-transfer
application/vnd.ntt-local.ogw_remote-access
application/vnd.ntt-local.sip-ta_remote
application/vnd.ntt-local.sip-ta_tcp_stream
application/vnd.oasis.opendocument.chart			odc
application/vnd.oasis.opendocument.chart-template		otc
application/vnd.oasis.opendocument.database			odb
application/vnd.oasis.opendocument.formula			odf
# otf: font/otf
application/vnd.oasis.opendocument.formula-template
application/vnd.oasis.opendocument.graphics			odg
application/vnd.oasis.opendocument.graphics-template		otg
application/vnd.oasis.opendocument.image			odi
application/vnd.oasis.opendocument.image-template		oti
application/vnd.oasis.opendocument.presentation			odp
application/vnd.oasis.opendocument.presentation-template	otp
application/vnd.oasis.opendocument.spreadsheet			ods
application/vnd.oasis.opendocument.spreadsheet-template		ots
application/vnd.oasis.opendocument.text				odt
application/vnd.oasis.opendocument.text-master			odm
application/vnd.oasis.opendocument.text-template		ott
application/vnd.oasis.opendocument.text-web			oth
application/vnd.obn
application/vnd.ocf+cbor
application/vnd.oftn.l10n+json
application/vnd.oipf.contentaccessdownload+xml
application/vnd.oipf.contentaccessstreaming+xml
application/vnd.oipf.cspg-hexbinary
application/vnd.oipf.dae.svg+xml
application/vnd.oipf.dae.xhtml+xml
application/vnd.oipf.mippvcontrolmessage+xml
application/vnd.oipf.pae.gem
application/vnd.oipf.spdiscovery+xml
application/vnd.oipf.spdlist+xml
application/vnd.oipf.ueprofile+xml
application/vnd.olpc-sugar			xo
application/vnd.oma.bcast.associated-procedure-parameter+xml
application/vnd.oma.bcast.drm-trigger+xml
application/vnd.oma.bcast.imd+xml
application/vnd.oma.bcast.ltkm
application/vnd.oma.bcast.notification+xml
application/vnd.oma.bcast.provisioningtrigger
application/vnd.oma.bcast.sgboot
application/vnd.oma.bcast.sgdd+xml
application/vnd.oma.bcast.sgdu
application/vnd.oma.bcast.simple-symbol-container
application/vnd.oma.bcast.smartcard-trigger+xml
application/vnd.oma.bcast.sprov+xml
application/vnd.oma.bcast.stkm
application/vnd.oma.cab-address-book+xml
application/vnd.oma.cab-feature-handler+xml
application/vnd.oma.cab-pcc+xml
application/vnd.oma.cab-subs-invite+xml
application/vnd.oma.cab-user-prefs+xml
application/vnd.oma.dcd
application/vnd.oma.dcdc
application/vnd.oma.dd2+xml			dd2
application/vnd.oma.drm.risd+xml
application/vnd.oma.group-usage-list+xml
application/vnd.oma.lwm2m+json
application/vnd.oma.lwm2m+tlv
application/vnd.oma.pal+xml
application/vnd.oma.poc.detailed-progress-report+xml
application/vnd.oma.poc.final-report+xml
application/vnd.oma.poc.groups+xml
application/vnd.oma.poc.invocation-descriptor+xml
application/vnd.oma.poc.optimized-progress-report+xml
application/vnd.oma.push
application/vnd.oma.scidm.messages+xml
application/vnd.oma.xcap-directory+xml
application/vnd.oma-scws-config
application/vnd.oma-scws-http-request
application/vnd.oma-scws-http-response
application/vnd.omads-email+xml
application/vnd.omads-file+xml
application/vnd.omads-folder+xml
application/vnd.omaloc-supl-init
application/vnd.onepager			tam
application/vnd.onepagertamp			tamp
application/vnd.onepagertamx			tamx
application/vnd.onepagertat			tat
application/vnd.onepagertatp			tatp
application/vnd.onepagertatx			tatx
application/vnd.openblox.game+xml		obgx
application/vnd.openblox.game-binary		obg
application/vnd.openeye.oeb			oeb
application/vnd.openofficeorg.extension		oxt
application/vnd.openstreetmap.data+xml		osm
application/vnd.openxmlformats-officedocument.custom-properties+xml
application/vnd.openxmlformats-officedocument.customXmlProperties+xml
application/vnd.openxmlformats-officedocument.drawing+xml
application/vnd.openxmlformats-officedocument.drawingml.chart+xml
application/vnd.openxmlformats-officedocument.drawingml.chartshapes+xml
application/vnd.openxmlformats-officedocument.drawingml.diagramColors+xml
application/vnd.openxmlformats-officedocument.drawingml.diagramData+xml
application/vnd.openxmlformats-officedocument.drawingml.diagramLayout+xml
application/vnd.openxmlformats-officedocument.drawingml.diagramStyle+xml
application/vnd.openxmlformats-officedocument.extended-properties+xml
application/vnd.openxmlformats-officedocument.presentationml.commentAuthors+xml
application/vnd.openxmlformats-officedocument.presentationml.comments+xml
application/vnd.openxmlformats-officedocument.presentationml.handoutMaster+xml
application/vnd.openxmlformats-officedocument.presentationml.notesMaster+xml
application/vnd.openxmlformats-officedocument.presentationml.notesSlide+xml
application/vnd.openxmlformats-officedocument.presentationml.presProps+xml
application/vnd.openxmlformats-officedocument.presentationml.presentation pptx
application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml
application/vnd.openxmlformats-officedocument.presentationml.slide	sldx
application/vnd.openxmlformats-officedocument.presentationml.slide+xml
application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml
application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml
application/vnd.openxmlformats-officedocument.presentationml.slideUpdateInfo+xml
application/vnd.openxmlformats-officedocument.presentationml.slideshow	ppsx
application/vnd.openxmlformats-officedocument.presentationml.slideshow.main+xml
application/vnd.openxmlformats-officedocument.presentationml.tableStyles+xml
application/vnd.openxmlformats-officedocument.presentationml.tags+xml
application/vnd.openxmlformats-officedocument.presentationml.template	potx
application/vnd.openxmlformats-officedocument.presentationml.template.main+xml
application/vnd.openxmlformats-officedocument.presentationml.viewProps+xml
application/vnd.openxmlformats-officedocument.spreadsheetml.calcChain+xml
application/vnd.openxmlformats-officedocument.spreadsheetml.chartsheet+xml
application/vnd.openxmlformats-officedocument.spreadsheetml.comments+xml
application/vnd.openxmlformats-officedocument.spreadsheetml.connections+xml
application/vnd.openxmlformats-officedocument.spreadsheetml.dialogsheet+xml
application/vnd.openxmlformats-officedocument.spreadsheetml.externalLink+xml
application/vnd.openxmlformats-officedocument.spreadsheetml.pivotCacheDefinition+xml
application/vnd.openxmlformats-officedocument.spreadsheetml.pivotCacheRecords+xml
application/vnd.openxmlformats-officedocument.spreadsheetml.pivotTable+xml
application/vnd.openxmlformats-officedocument.spreadsheetml.queryTable+xml
application/vnd.openxmlformats-officedocument.spreadsheetml.revisionHeaders+xml
application/vnd.openxmlformats-officedocument.spreadsheetml.revisionLog+xml
application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml
application/vnd.openxmlformats-officedocument.spreadsheetml.sheet	xlsx
application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml
application/vnd.openxmlformats-officedocument.spreadsheetml.sheetMetadata+xml
application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml
application/vnd.openxmlformats-officedocument.spreadsheetml.table+xml
application/vnd.openxmlformats-officedocument.spreadsheetml.tableSingleCells+xml
application/vnd.openxmlformats-officedocument.spreadsheetml.template	xltx
application/vnd.openxmlformats-officedocument.spreadsheetml.template.main+xml
application/vnd.openxmlformats-officedocument.spreadsheetml.userNames+xml
application/vnd.openxmlformats-officedocument.spreadsheetml.volatileDependencies+xml
application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml
application/vnd.openxmlformats-officedocument.theme+xml
application/vnd.openxmlformats-officedocument.themeOverride+xml
application/vnd.openxmlformats-officedocument.vmlDrawing
application/vnd.openxmlformats-officedocument.wordprocessingml.comments+xml
application/vnd.openxmlformats-officedocument.wordprocessingml.document	docx
application/vnd.openxmlformats-officedocument.wordprocessingml.document.glossary+xml
application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml
application/vnd.openxmlformats-officedocument.wordprocessingml.endnotes+xml
application/vnd.openxmlformats-officedocument.wordprocessingml.fontTable+xml
application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml
application/vnd.openxmlformats-officedocument.wordprocessingml.footnotes+xml
application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml
application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml
application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml
application/vnd.openxmlformats-officedocument.wordprocessingml.template	dotx
application/vnd.openxmlformats-officedocument.wordprocessingml.template.main+xml
application/vnd.openxmlformats-officedocument.wordprocessingml.webSettings+xml
application/vnd.openxmlformats-package.core-properties+xml
application/vnd.openxmlformats-package.digital-signature-xmlsignature+xml
application/vnd.openxmlformats-package.relationships+xml
application/vnd.oracle.resource+json
application/vnd.orange.indata
application/vnd.osa.netdeploy			ndc
application/vnd.osgeo.mapguide.package		mgp
# jar: application/x-java-archive
application/vnd.osgi.bundle
application/vnd.osgi.dp				dp
application/vnd.osgi.subsystem			esa
application/vnd.otps.ct-kip+xml
application/vnd.oxli.countgraph			oxlicg
application/vnd.pagerduty+json
application/vnd.palm				prc pdb pqa oprc
application/vnd.panoply				plp
application/vnd.paos+xml
application/vnd.pawaafile			paw
application/vnd.pcos
application/vnd.pg.format		    	str
application/vnd.pg.osasli			ei6
application/vnd.piaccess.application-license	pil
application/vnd.picsel				efif
application/vnd.pmi.widget			wg
application/vnd.poc.group-advertisement+xml
application/vnd.pocketlearn			plf
application/vnd.powerbuilder6			pbd
application/vnd.powerbuilder6-s
application/vnd.powerbuilder7
application/vnd.powerbuilder7-s
application/vnd.powerbuilder75
application/vnd.powerbuilder75-s
application/vnd.preminet			preminet
application/vnd.previewsystems.box		box vbox
application/vnd.proteus.magazine		mgz
application/vnd.publishare-delta-tree		qps
# pti: image/prs.pti
application/vnd.pvi.ptid1			ptid
application/vnd.pwg-multiplexed
application/vnd.pwg-xhtml-print+xml
application/vnd.qualcomm.brew-app-res		bar
application/vnd.quarantainenet
application/vnd.Quark.QuarkXPress		qxd qxt qwd qwt qxl qxb
application/vnd.quobject-quoxdocument		quox quiz
application/vnd.radisys.moml+xml
application/vnd.radisys.msml-audit-conf+xml
application/vnd.radisys.msml-audit-conn+xml
application/vnd.radisys.msml-audit-dialog+xml
application/vnd.radisys.msml-audit-stream+xml
application/vnd.radisys.msml-audit+xml
application/vnd.radisys.msml-conf+xml
application/vnd.radisys.msml-dialog-base+xml
application/vnd.radisys.msml-dialog-fax-detect+xml
application/vnd.radisys.msml-dialog-fax-sendrecv+xml
application/vnd.radisys.msml-dialog-group+xml
application/vnd.radisys.msml-dialog-speech+xml
application/vnd.radisys.msml-dialog-transform+xml
application/vnd.radisys.msml-dialog+xml
application/vnd.radisys.msml+xml
application/vnd.rainstor.data			tree
application/vnd.rapid
application/vnd.rar				rar
application/vnd.realvnc.bed			bed
application/vnd.recordare.musicxml		mxl
application/vnd.recordare.musicxml+xml
application/vnd.RenLearn.rlprint
application/vnd.rig.cryptonote			cryptonote
application/vnd.route66.link66+xml		link66
# gbr: application/rpki-ghostbusters
application/vnd.rs-274x
application/vnd.ruckus.download
application/vnd.s3sms
application/vnd.sailingtracker.track		st
application/vnd.sbm.cid
application/vnd.sbm.mid2
application/vnd.scribus				scd sla slaz
application/vnd.sealed.3df			s3df
application/vnd.sealed.csf			scsf
application/vnd.sealed.doc			sdoc sdo s1w
application/vnd.sealed.eml			seml sem
application/vnd.sealed.mht			smht smh
application/vnd.sealed.net
# spp: application/scvp-vp-response
application/vnd.sealed.ppt			sppt s1p
application/vnd.sealed.tiff			stif
application/vnd.sealed.xls			sxls sxl s1e
# stm: audio/x-stm
application/vnd.sealedmedia.softseal.html	stml s1h
application/vnd.sealedmedia.softseal.pdf	spdf spd s1a
application/vnd.seemail				see
application/vnd.sema				sema
application/vnd.semd				semd
application/vnd.semf				semf
application/vnd.shana.informed.formdata		ifm
application/vnd.shana.informed.formtemplate	itp
application/vnd.shana.informed.interchange	iif
application/vnd.shana.informed.package		ipk
application/vnd.SimTech-MindMapper		twd twds
application/vnd.siren+json
application/vnd.smaf				mmf
application/vnd.smart.notebook			notebook
application/vnd.smart.teacher			teacher
application/vnd.software602.filler.form+xml	fo
application/vnd.software602.filler.form-xml-zip	zfo
application/vnd.solent.sdkm+xml			sdkm sdkd
application/vnd.spotfire.dxp			dxp
application/vnd.spotfire.sfs			sfs
application/vnd.sss-cod
application/vnd.sss-dtf
application/vnd.sss-ntf
application/vnd.stepmania.package		smzip
application/vnd.stepmania.stepchart		sm
application/vnd.street-stream
application/vnd.sun.wadl+xml			wadl
application/vnd.sus-calendar			sus susp
application/vnd.svd
application/vnd.swiftview-ics
application/vnd.syncml+xml			xsm
application/vnd.syncml.dm+wbxml			bdm
application/vnd.syncml.dm+xml			xdm
application/vnd.syncml.dm.notification
application/vnd.syncml.dmddf+wbxml
application/vnd.syncml.dmddf+xml		ddf
application/vnd.syncml.dmtnds+wbxml
application/vnd.syncml.dmtnds+xml
application/vnd.syncml.ds.notification
application/vnd.tableschema+json
application/vnd.tao.intent-module-archive	tao
application/vnd.tcpdump.pcap			pcap cap dmp
application/vnd.theqvd				qvd
application/vnd.tmd.mediaflex.api+xml
application/vnd.tml				vfr viaframe
application/vnd.tmobile-livetv			tmo
application/vnd.tri.onesource
application/vnd.trid.tpt			tpt
application/vnd.triscape.mxs			mxs
application/vnd.trueapp				tra
application/vnd.truedoc
# cab: application/vnd.ms-cab-compressed
application/vnd.ubisoft.webplayer
application/vnd.ufdl				ufdl ufd frm
application/vnd.uiq.theme			utz
application/vnd.umajin				umj
application/vnd.unity				unityweb
application/vnd.uoml+xml			uoml uo
application/vnd.uplanet.alert
application/vnd.uplanet.alert-wbxml
application/vnd.uplanet.bearer-choice
application/vnd.uplanet.bearer-choice-wbxml
application/vnd.uplanet.cacheop
application/vnd.uplanet.cacheop-wbxml
application/vnd.uplanet.channel
application/vnd.uplanet.channel-wbxml
application/vnd.uplanet.list
application/vnd.uplanet.list-wbxml
application/vnd.uplanet.listcmd
application/vnd.uplanet.listcmd-wbxml
application/vnd.uplanet.signal
application/vnd.uri-map				urim urimap
application/vnd.valve.source.material		vmt
application/vnd.vcx				vcx
# sxi: application/vnd.sun.xml.impress
application/vnd.vd-study			mxi study-inter model-inter
# mcd: application/vnd.mcd
application/vnd.vectorworks			vwx
application/vnd.vel+json
application/vnd.verimatrix.vcas
application/vnd.vidsoft.vidconference		vsc
application/vnd.visio				vsd vst vsw vss
application/vnd.visionary			vis
# vsc: application/vnd.vidsoft.vidconference
application/vnd.vividence.scriptfile
application/vnd.vsf				vsf
application/vnd.wap.sic				sic
application/vnd.wap.slc				slc
application/vnd.wap.wbxml			wbxml
application/vnd.wap.wmlc			wmlc
application/vnd.wap.wmlscriptc			wmlsc
application/vnd.webturbo			wtb
application/vnd.wfa.p2p				p2p
application/vnd.wfa.wsc				wsc
application/vnd.windows.devicepairing
application/vnd.wmc				wmc
application/vnd.wmf.bootstrap
# nb: application/mathematica for now
application/vnd.wolfram.mathematica
application/vnd.wolfram.mathematica.package	m
application/vnd.wolfram.player			nbp
application/vnd.wordperfect			wpd
application/vnd.wqd				wqd
application/vnd.wrq-hp3000-labelled
application/vnd.wt.stf				stf
application/vnd.wv.csp+xml
application/vnd.wv.csp+wbxml			wv
application/vnd.wv.ssp+xml
application/vnd.xacml+json
application/vnd.xara				xar
application/vnd.xfdl				xfdl xfd
application/vnd.xfdl.webform
application/vnd.xmi+xml
application/vnd.xmpie.cpkg			cpkg
application/vnd.xmpie.dpkg			dpkg
# dpkg: application/vnd.xmpie.dpkg
application/vnd.xmpie.plan
application/vnd.xmpie.ppkg			ppkg
application/vnd.xmpie.xlim			xlim
application/vnd.yamaha.hv-dic			hvd
application/vnd.yamaha.hv-script		hvs
application/vnd.yamaha.hv-voice			hvp
application/vnd.yamaha.openscoreformat		osf
application/vnd.yamaha.openscoreformat.osfpvg+xml
application/vnd.yamaha.remote-setup
application/vnd.yamaha.smaf-audio		saf
application/vnd.yamaha.smaf-phrase		spf
application/vnd.yamaha.through-ngn
application/vnd.yamaha.tunnel-udpencap
application/vnd.yaoweme				yme
application/vnd.yellowriver-custom-menu		cmp
application/vnd.zul				zir zirz
application/vnd.zzazz.deck+xml			zaz
application/voicexml+xml			vxml
application/vq-rtcp-xr
application/watcherinfo+xml			wif
application/whoispp-query
application/whoispp-response
application/widget				wgt
application/wita
application/wordperfect5.1
application/wsdl+xml				wsdl
application/wspolicy+xml			wspolicy
# yes, this *is* IANA registered despite of x-
application/x-www-form-urlencoded
application/x400-bp
application/xacml+xml
application/xcap-att+xml			xav
application/xcap-caps+xml			xca
application/xcap-diff+xml			xdf
application/xcap-el+xml				xel
application/xcap-error+xml			xer
application/xcap-ns+xml				xns
application/xcon-conference-info-diff+xml
application/xcon-conference-info+xml
application/xenc+xml
application/xhtml+xml				xhtml xhtm xht
# xml, xsd, rng: text/xml
application/xml
# mod: audio/x-mod
application/xml-dtd				dtd
# ent: text/xml-external-parsed-entity
application/xml-external-parsed-entity
application/xml-patch+xml
application/xmpp+xml
application/xop+xml				xop
application/xslt+xml				xsl xslt
application/xv+xml				mxml xhvml xvml xvm
application/yang				yang
application/yang-data+json
application/yang-data+xml
application/yang-patch+json
application/yang-patch+xml
application/yin+xml				yin
application/zip					zip
application/zlib
audio/1d-interleaved-parityfec
audio/32kadpcm					726
# 3gp, 3gpp: video/3gpp
audio/3gpp
# 3g2, 3gpp2: video/3gpp2
audio/3gpp2
audio/ac3					ac3
audio/AMR					amr
audio/AMR-WB					awb
audio/amr-wb+
audio/aptx
audio/asc					acn
# aa3, omg: audio/ATRAC3
audio/ATRAC-ADVANCED-LOSSLESS			aal
# aa3, omg: audio/ATRAC3
audio/ATRAC-X					atx
audio/ATRAC3					at3 aa3 omg
audio/basic					au snd
audio/BV16
audio/BV32
audio/clearmode
audio/CN
audio/DAT12
audio/dls					dls
audio/dsr-es201108
audio/dsr-es202050
audio/dsr-es202211
audio/dsr-es202212
audio/DV
audio/DVI4
audio/eac3
audio/encaprtp
audio/EVRC					evc
# qcp: audio/qcelp
audio/EVRC-QCP
audio/EVRC0
audio/EVRC1
audio/EVRCB					evb
audio/EVRCB0
audio/EVRCB1
audio/EVRCNW					enw
audio/EVRCNW0
audio/EVRCNW1
audio/EVRCWB					evw
audio/EVRCWB0
audio/EVRCWB1
audio/EVS
audio/example
audio/fwdred
audio/G711-0
audio/G719
audio/G722
audio/G7221
audio/G723
audio/G726-16
audio/G726-24
audio/G726-32
audio/G726-40
audio/G728
audio/G729
audio/G7291
audio/G729D
audio/G729E
audio/GSM
audio/GSM-EFR
audio/GSM-HR-08
audio/iLBC					lbc
audio/ip-mr_v2.5
# wav: audio/x-wav
audio/L16					l16
audio/L20
audio/L24
audio/L8
audio/LPC
audio/MELP
audio/MELP600
audio/MELP1200
audio/MELP2400
audio/mobile-xmf				mxmf
# mp4, mpg4: video/mp4, see RFC 4337
audio/mp4					m4a
audio/MP4A-LATM
audio/MPA
audio/mpa-robust
audio/mpeg					mp3 mpga mp1 mp2
audio/mpeg4-generic
audio/ogg					oga ogg opus spx
audio/opus
audio/parityfec
audio/PCMA
audio/PCMA-WB
audio/PCMU
audio/PCMU-WB
audio/prs.sid					sid psid
audio/qcelp					qcp
audio/raptorfec
audio/RED
audio/rtp-enc-aescm128
audio/rtp-midi
audio/rtploopback
audio/rtx
audio/SMV					smv
# qcp: audio/qcelp, see RFC 3625
audio/SMV-QCP
audio/SMV0
# mid: audio/midi
audio/sp-midi
audio/speex
audio/t140c
audio/t38
audio/telephone-event
audio/tone
audio/UEMCLIP
audio/ulpfec
audio/VDVI
audio/VMR-WB
audio/vnd.3gpp.iufp
audio/vnd.4SB
audio/vnd.audikoz				koz
audio/vnd.CELP
audio/vnd.cisco.nse
audio/vnd.cmles.radio-events
audio/vnd.cns.anp1
audio/vnd.cns.inf1
audio/vnd.dece.audio				uva uvva
audio/vnd.digital-winds				eol
audio/vnd.dlna.adts
audio/vnd.dolby.heaac.1
audio/vnd.dolby.heaac.2
audio/vnd.dolby.mlp				mlp
audio/vnd.dolby.mps
audio/vnd.dolby.pl2
audio/vnd.dolby.pl2x
audio/vnd.dolby.pl2z
audio/vnd.dolby.pulse.1
audio/vnd.dra
# wav: audio/x-wav, cpt: application/mac-compactpro
audio/vnd.dts					dts
audio/vnd.dts.hd				dtshd
# dvb: video/vnd.dvb.file
audio/vnd.dvb.file
audio/vnd.everad.plj				plj
# rm: audio/x-pn-realaudio
audio/vnd.hns.audio
audio/vnd.lucent.voice				lvp
audio/vnd.ms-playready.media.pya		pya
# mxmf: audio/mobile-xmf
audio/vnd.nokia.mobile-xmf
audio/vnd.nortel.vbk				vbk
audio/vnd.nuera.ecelp4800			ecelp4800
audio/vnd.nuera.ecelp7470			ecelp7470
audio/vnd.nuera.ecelp9600			ecelp9600
audio/vnd.octel.sbc
# audio/vnd.qcelp deprecated in favour of audio/qcelp
audio/vnd.rhetorex.32kadpcm
audio/vnd.rip					rip
audio/vnd.sealedmedia.softseal.mpeg		smp3 smp s1m
audio/vnd.vmx.cvsd
audio/vorbis
audio/vorbis-config
font/collection					ttc
font/otf					otf
font/sfnt
font/ttf					ttf
font/woff					woff
font/woff2					woff2
image/bmp					bmp dib
image/cgm					cgm
image/dicom-rle					drle
image/emf					emf
image/example
image/fits					fits fit fts
image/g3fax
image/gif					gif
image/ief					ief
image/jls					jls
image/jp2					jp2 jpg2
image/jpeg					jpg jpeg jpe jfif
image/jpm					jpm jpgm
image/jpx					jpx jpf
image/ktx					ktx
image/naplps
image/png					png
image/prs.btif					btif btf
image/prs.pti					pti
image/pwg-raster
image/svg+xml					svg svgz
image/t38					t38
image/tiff					tiff tif
image/tiff-fx					tfx
image/vnd.adobe.photoshop			psd
image/vnd.airzip.accelerator.azv		azv
image/vnd.cns.inf2
image/vnd.dece.graphic				uvi uvvi uvg uvvg
image/vnd.djvu					djvu djv
# sub: text/vnd.dvb.subtitle
image/vnd.dvb.subtitle
image/vnd.dwg					dwg
image/vnd.dxf					dxf
image/vnd.fastbidsheet				fbs
image/vnd.fpx					fpx
image/vnd.fst					fst
image/vnd.fujixerox.edmics-mmr			mmr
image/vnd.fujixerox.edmics-rlc			rlc
image/vnd.globalgraphics.pgb			pgb
image/vnd.microsoft.icon			ico
image/vnd.mix
image/vnd.mozilla.apng				apng
image/vnd.ms-modi				mdi
image/vnd.net-fpx
image/vnd.radiance				hdr rgbe xyze
image/vnd.sealed.png				spng spn s1n
image/vnd.sealedmedia.softseal.gif		sgif sgi s1g
image/vnd.sealedmedia.softseal.jpg		sjpg sjp s1j
image/vnd.svf
image/vnd.tencent.tap				tap
image/vnd.valve.source.texture			vtf
image/vnd.wap.wbmp				wbmp
image/vnd.xiff					xif
image/vnd.zbrush.pcx				pcx
image/wmf					wmf
message/CPIM
message/delivery-status
message/disposition-notification
message/example
message/external-body
message/feedback-report
message/global					u8msg
message/global-delivery-status			u8dsn
message/global-disposition-notification		u8mdn
message/global-headers				u8hdr
message/http
# cl: application/simple-filter+xml
message/imdn+xml
# message/news obsoleted by message/rfc822
message/partial
message/rfc822					eml mail art
message/s-http
message/sip
message/sipfrag
message/tracking-status
message/vnd.si.simp
# wsc: application/vnd.wfa.wsc
message/vnd.wfa.wsc
model/example
model/gltf+json					gltf
model/iges					igs iges
model/mesh					msh mesh silo
model/vnd.collada+xml				dae
model/vnd.dwf					dwf
# 3dml, 3dm: text/vnd.in3d.3dml
model/vnd.flatland.3dml
model/vnd.gdl					gdl gsm win dor lmp rsm msm ism
model/vnd.gs-gdl
model/vnd.gtw					gtw
model/vnd.moml+xml				moml
model/vnd.mts					mts
model/vnd.opengex				ogex
model/vnd.parasolid.transmit.binary		x_b xmt_bin
model/vnd.parasolid.transmit.text		x_t xmt_txt
model/vnd.rosette.annotated-data-model
model/vnd.valve.source.compiled-map		bsp
model/vnd.vtu					vtu
model/vrml					wrl vrml
# x3db: model/x3d+xml
model/x3d+fastinfoset
# x3d: application/vnd.hzn-3d-crossword
model/x3d+xml					x3db
model/x3d-vrml					x3dv x3dvz
multipart/alternative
multipart/appledouble
multipart/byteranges
multipart/digest
multipart/encrypted
multipart/form-data
multipart/header-set
multipart/mixed
multipart/parallel
multipart/related
multipart/report
multipart/signed
multipart/vnd.bint.med-plus			bmed
multipart/voice-message				vpm
multipart/x-mixed-replace
text/1d-interleaved-parityfec
text/cache-manifest				appcache manifest
text/calendar					ics ifb
text/css					css
text/csv					csv
text/csv-schema					csvs
text/directory
text/dns					soa zone
text/encaprtp
# text/ecmascript obsoleted by application/ecmascript
text/enriched
text/example
text/fwdred
text/grammar-ref-list
text/html					html htm
# text/javascript obsoleted by application/javascript
text/jcr-cnd					cnd
text/markdown					markdown md
text/mizar					miz
text/n3						n3
text/parameters
text/parityfec
text/plain		txt asc text pm el c h cc hh cxx hxx f90 conf log
text/provenance-notation			provn
text/prs.fallenstein.rst			rst
text/prs.lines.tag				tag dsc
text/prs.prop.logic
text/raptorfec
text/RED
text/rfc822-headers
text/richtext					rtx
# rtf: application/rtf
text/rtf
text/rtp-enc-aescm128
text/rtploopback
text/rtx
text/sgml					sgml sgm
text/strings
text/t140
text/tab-separated-values			tsv
text/troff					t tr roff
text/turtle					ttl
text/ulpfec
text/uri-list					uris uri
text/vcard					vcf vcard
text/vnd.a					a
text/vnd.abc					abc
text/vnd.ascii-art				ascii
# curl: application/vnd.curl
text/vnd.curl
text/vnd.debian.copyright			copyright
text/vnd.DMClientScript				dms
text/vnd.dvb.subtitle				sub
text/vnd.esmertec.theme-descriptor		jtd
text/vnd.fly					fly
text/vnd.fmi.flexstor				flx
text/vnd.graphviz				gv dot
text/vnd.in3d.3dml				3dml 3dm
text/vnd.in3d.spot				spot spo
text/vnd.IPTC.NewsML
text/vnd.IPTC.NITF
text/vnd.latex-z
text/vnd.motorola.reflex
text/vnd.ms-mediapackage			mpf
text/vnd.net2phone.commcenter.command		ccc
text/vnd.radisys.msml-basic-layout
text/vnd.si.uricatalogue			uric
text/vnd.sun.j2me.app-descriptor		jad
text/vnd.trolltech.linguist			ts
text/vnd.wap.si					si
text/vnd.wap.sl					sl
text/vnd.wap.wml				wml
text/vnd.wap.wmlscript				wmls
text/xml					xml xsd rng
text/xml-external-parsed-entity			ent
video/1d-interleaved-parityfec
video/3gpp					3gp 3gpp
video/3gpp2					3g2 3gpp2
video/3gpp-tt
video/BMPEG
video/BT656
video/CelB
video/DV
video/encaprtp
video/example
video/H261
video/H263
video/H263-1998
video/H263-2000
video/H264
video/H264-RCDO
video/H264-SVC
video/H265
video/iso.segment				m4s
video/JPEG
video/jpeg2000
video/mj2					mj2 mjp2
video/MP1S
video/MP2P
video/MP2T
video/mp4					mp4 mpg4 m4v
video/MP4V-ES
video/mpeg					mpeg mpg mpe m1v m2v
video/mpeg4-generic
video/MPV
video/nv
video/ogg					ogv
video/parityfec
video/pointer
video/quicktime					mov qt
video/raptorfec
video/raw
video/rtp-enc-aescm128
video/rtploopback
video/rtx
video/SMPTE292M
video/ulpfec
video/vc1
video/vnd.CCTV
video/vnd.dece.hd				uvh uvvh
video/vnd.dece.mobile				uvm uvvm
video/vnd.dece.mp4				uvu uvvu
video/vnd.dece.pd				uvp uvvp
video/vnd.dece.sd				uvs uvvs
video/vnd.dece.video				uvv uvvv
video/vnd.directv.mpeg
video/vnd.directv.mpeg-tts
video/vnd.dlna.mpeg-tts
video/vnd.dvb.file				dvb
video/vnd.fvt					fvt
# rm: audio/x-pn-realaudio
video/vnd.hns.video
video/vnd.iptvforum.1dparityfec-1010
video/vnd.iptvforum.1dparityfec-2005
video/vnd.iptvforum.2dparityfec-1010
video/vnd.iptvforum.2dparityfec-2005
video/vnd.iptvforum.ttsavc
video/vnd.iptvforum.ttsmpeg2
video/vnd.motorola.video
video/vnd.motorola.videop
video/vnd.mpegurl				mxu m4u
video/vnd.ms-playready.media.pyv		pyv
video/vnd.nokia.interleaved-multimedia		nim
video/vnd.nokia.videovoip
# mp4: video/mp4
video/vnd.objectvideo
video/vnd.radgamettools.bink			bik bk2
video/vnd.radgamettools.smacker			smk
video/vnd.sealed.mpeg1				smpg s11
# smpg: video/vnd.sealed.mpeg1
video/vnd.sealed.mpeg4				s14
video/vnd.sealed.swf				sswf ssw
video/vnd.sealedmedia.softseal.mov		smov smo s1q
# uvu, uvvu: video/vnd.dece.mp4
video/vnd.uvvu.mp4
video/vnd.vivo					viv
video/VP8

# Non-IANA types

application/mac-compactpro			cpt
application/metalink+xml			metalink
application/owl+xml				owx
application/rss+xml				rss
application/vnd.android.package-archive		apk
application/vnd.oma.dd+xml			dd
application/vnd.oma.drm.content			dcf
# odf: application/vnd.oasis.opendocument.formula
application/vnd.oma.drm.dcf			o4a o4v
application/vnd.oma.drm.message			dm
application/vnd.oma.drm.rights+wbxml		drc
application/vnd.oma.drm.rights+xml		dr
application/vnd.sun.xml.calc			sxc
application/vnd.sun.xml.calc.template		stc
application/vnd.sun.xml.draw			sxd
application/vnd.sun.xml.draw.template		std
application/vnd.sun.xml.impress			sxi
application/vnd.sun.xml.impress.template	sti
application/vnd.sun.xml.math			sxm
application/vnd.sun.xml.writer			sxw
application/vnd.sun.xml.writer.global		sxg
application/vnd.sun.xml.writer.template		stw
application/vnd.symbian.install			sis
application/vnd.wap.mms-message			mms
application/x-annodex				anx
application/x-bcpio				bcpio
application/x-bittorrent			torrent
application/x-bzip2				bz2
application/x-cdlink				vcd
application/x-chrome-extension			crx
application/x-cpio				cpio
application/x-csh				csh
application/x-director				dcr dir dxr
application/x-dvi				dvi
application/x-futuresplash			spl
application/x-gtar				gtar
application/x-hdf				hdf
application/x-java-archive			jar
application/x-java-jnlp-file			jnlp
application/x-java-pack200			pack
application/x-killustrator			kil
application/x-latex				latex
application/x-netcdf				nc cdf
application/x-perl				pl
application/x-rpm				rpm
application/x-sh				sh
application/x-shar				shar
application/x-stuffit				sit
application/x-sv4cpio				sv4cpio
application/x-sv4crc				sv4crc
application/x-tar				tar
application/x-tcl				tcl
application/x-tex				tex
application/x-texinfo				texinfo texi
application/x-troff-man				man 1 2 3 4 5 6 7 8
application/x-troff-me				me
application/x-troff-ms				ms
application/x-ustar				ustar
application/x-wais-source			src
application/x-xpinstall				xpi
application/x-xspf+xml				xspf
application/x-xz				xz
audio/midi					mid midi kar
audio/x-aiff					aif aiff aifc
audio/x-annodex					axa
audio/x-flac					flac
audio/x-matroska				mka
audio/x-mod					mod ult uni m15 mtm 669 med
audio/x-mpegurl					m3u
audio/x-ms-wax					wax
audio/x-ms-wma					wma
audio/x-pn-realaudio				ram rm
audio/x-realaudio				ra
audio/x-s3m					s3m
audio/x-stm					stm
audio/x-wav					wav
chemical/x-xyz					xyz
image/webp					webp
image/x-cmu-raster				ras
image/x-portable-anymap				pnm
image/x-portable-bitmap				pbm
image/x-portable-graymap			pgm
image/x-portable-pixmap				ppm
image/x-rgb					rgb
image/x-targa					tga
image/x-xbitmap					xbm
image/x-xpixmap					xpm
image/x-xwindowdump				xwd
text/html-sandboxed				sandboxed
text/x-pod					pod
text/x-setext					etx
video/webm					webm
video/x-annodex					axv
video/x-flv					flv
video/x-javafx					fxm
video/x-matroska				mkv
video/x-matroska-3d				mk3d
video/x-ms-asf					asx
video/x-ms-wm					wm
video/x-ms-wmv					wmv
video/x-ms-wmx					wmx
video/x-ms-wvx					wvx
video/x-msvideo					avi
video/x-sgi-movie				movie
x-conference/x-cooltalk				ice
x-epoc/x-sisx-app				sisx

=end comment
