function radioRefresh() {
	if ( V.query.length ) {
		var query = V.query.slice( -1 )[ 0 ];
		list( query, function( html ) {
			var data = {
				  html      : html
				, modetitle : query.modetitle
				, path      : query.path
			}
			renderLibraryList( data );
		} );
	} else {
		$( '#mode-'+ V.mode ).trigger( 'click' );
	}
}
function statusUpdate( data ) {
	$.each( data, ( k, v ) => { S[ k ] = v } ); // need braces
	if ( ! $( '#playback' ).hasClass( 'i-'+ S.player ) ) displayBottom();
	setButtonControl();
	if ( D.snapclient ) bash( [ 'lcdcharrefresh', JSON.stringify( S ) ] );
}
function webradioIcon( srcnoext ) {
	var radiourl = decodeURIComponent( srcnoext )
					.split( '/' ).pop()
					.replace( /\|/g, '/' );
	return $( '#lib-list li' ).filter( ( i, el ) => {
		return $( el ).find( '.lipath' ).text() === radiourl;
	} ).find( '.li-icon' );
}
// page resize -----------------------------------------------------------------
window.addEventListener( 'resize', () => { // resize / rotate
	var wW = window.innerWidth;
	if ( V.wW === wW ) return // wH changes with address bar toggle on scroll up-down
	
	V.wH = window.innerHeight;
	V.wW = wW;
	setTimeout( () => {
		var barvisible = $bartop.is( ':visible' );
		if ( V.playback ) {
			displayPlayback();
			setButtonControl();
			setTimeout( renderPlayback, 50 );
			setInfoScroll();
			var $bioimg = $( '#bioimg' );
			if ( $bioimg.length ) {
				var $title = $( '#biocontent .artist' );
				V.wW < 481 ? $title.insertBefore( $bioimg ) : $title.insertAfter( $bioimg );
			}
		} else if ( V.library ) {
			if ( V.librarylist ) {
				if ( V.librarytrack ) $( '.liinfo' ).css( 'width', ( wW - $( '.licoverimg img' ).width() - 50 ) );
				renderLibraryPadding();
			}
		} else {
			renderPlaylistPadding();
			if ( ! V.savedpl && ! V.savedpltrack ) {
				setTimeout( () => {
					setPlaylistInfoWidth();
					setPlaylistScroll();
				}, 600 );
			}
		}
		displayBars();
	}, 0 );
} );
// pushstreamChannel() in common.js
var channels = [ 'airplay', 'bookmark', 'btreceiver', 'coverart',  'display', 'equalizer', 'mpdplayer',     'mpdradio', 'mpdupdate', 'notify',
				 'option',  'order',    'playlist',   'radiolist', 'relays',  'reload',    'savedplaylist', 'volume',   'webradio' ];
if ( ! localhost ) channels.push( 'vumeter' );
pushstreamChannel( channels );
function pushstreamDisconnect() {
	clearIntervalAll();
	guideHide();
	if ( $( '#infoIcon' ).hasClass( 'i-relays' ) ) $( '#infoX' ).trigger( 'click' );
}
pushstream.onmessage = ( data, id, channel ) => {
	switch ( channel ) {
		case 'airplay':       psAirplay( data );        break;
		case 'bookmark':      psBookmark( data );       break;
		case 'btreceiver':    psBtReceiver( data );     break;
		case 'coverart':      psCoverart( data );       break;
		case 'display':       psDisplay( data );        break;
		case 'equalizer':     psEqualizer( data );      break;
		case 'mpdplayer':     psMpdPlayer( data );      break;
		case 'mpdradio':      psMpdRadio( data );       break;
		case 'mpdupdate':     psMpdUpdate( data );      break;
		case 'notify':        psNotify( data );         break;
		case 'option':        psOption( data );         break;
		case 'order':         psOrder( data );          break;
		case 'playlist':      psPlaylist( data );       break;
		case 'savedplaylist': psSavedPlaylists( data ); break;
		case 'radiolist':     psRadioList( data );      break;
		case 'relays':        psRelays( data );         break;
		case 'reload':        location.reload();        break;
		case 'restore':       psRestore( data );        break;
		case 'volume':        psVolume( data );         break;
		case 'vumeter':       psVUmeter( data );        break;
	}
}
function psAirplay( data ) {
	statusUpdate( data );
	if ( V.playback ) renderPlayback();
}
function psBtReceiver( connected ) {
	var prefix = $time.is( ':visible' ) ? 'ti' : 'i';
	$( '#'+ prefix +'-btsender' ).toggleClass( 'hide', ! connected );
}
function psBookmark() {
	V.libraryhtml = '';
	refreshData();
}
function psCoverart( data ) {
	clearTimeout( V.timeoutCover );
	bannerHide();
	$( '#coverart, #liimg' ).css( 'opacity', '' );
	data.type === 'coverart' ? S.coverart = data.url : S.stationcover = data.url;
	setCoverart();
	if ( 'Album' in data ) { // online coverarts come with album name
		S.Album = data.Album;
		setInfo();
	}
	if ( V.library && data.url.slice( 0, 13 ) === '/data/audiocd' ) return
	
	V.libraryhtml = V.librarylisthtml = V.playlisthtml = '';
	if ( ! V.playback ) refreshData();
}
function psDisplay( data ) {
	bannerHide();
	if ( 'submenu' in data ) {
		D[ data.submenu ] = data.value;
		displaySubMenu();
		return
	}
	
	if ( 'updateaddons' in data ) {
		S.updateaddons = data.updateaddons ? true : false;
		setButtonUpdateAddons();
		return
	}
	
	$.each( data, ( k, v ) => { D[ k ] = v } ); // need braces
	V.coverdefault = ! D.covervu && ! D.vumeter ? V.coverart : V.covervu;
	if ( ! D.covervu && ! D.vumeter ) {
		$( '#vu' ).remove();
	} else if ( ! $( '#vu' ).length ) {
		$.get( '/assets/img/vu.svg', data => $( '#coverart' ).after( '<div id="vu">'+ data +'</div>' ), 'text' );
	}
	displayBars();
	if ( V.playback ) {
		setButtonControl();
		displayPlayback();
		renderPlayback();
	} else if ( V.library ) {
		if ( ! V.librarylist ) {
			renderLibrary();
		} else if ( $( '.li-icon' ).eq( 0 ).hasClass( 'i-music' ) ) {
			if ( D.hidecover ) {
				$( '.licover' ).remove();
			} else {
				var query = V.query.slice( -1 )[ 0 ];
				list( query, function( html ) {
					var data = {
						  html      : html
						, modetitle : query.modetitle
						, path      : query.path
					}
					renderLibraryList( data );
				} );
			}
		}
		$( '#button-lib-back' ).toggleClass( 'back-left', D.backonleft );
	}
}
function psEqualizer( data ) {
	if ( V.local || ! ( 'active' in E ) ) return
	
	E        = data;
	eqOptionPreset();
}
function psMpdPlayer( data ) {
	clearTimeout( V.debouncempdplayer );
	V.debouncempdplayer = setTimeout( () => {
		if ( data.state === 'play' && ! data.Title && [ 'radiofrance', 'radioparadise' ].includes( data.icon ) ) {
			bash( [ 'radiorestart' ] ); // fix slow wi-fi - on station changed
		}
		if ( ! data.control && data.volume == -1 ) { // fix - upmpdcli missing values on stop/pause
			delete data.control;
			delete data.volume;
		}
		statusUpdate( data );
		if ( V.playback ) {
			renderPlaybackAll();
		} else if ( V.library ) {
			refreshData();
		} else {
			setPlaylistScroll();
		}
	}, 300 );
}
function psMpdRadio( data ) {
	statusUpdate( data );
	setProgress( 0 );
	if ( V.playback ) {
		setInfo();
		setCoverart();
		if ( D.radioelapsed ) {
			$( '#progress' ).html( ico( 'play' ) +'<span></span>' );
			setProgressElapsed();
		} else {
			setBlinkDot();
		}
	} else if ( V.playlist ) {
		setPlaylistScroll();
	}
}	
function psMpdUpdate( data ) {
	if ( 'type' in data ) {
		if ( data.type === 'mpd' ) {
			S.updating_db = true;
		} else {
			S.updatingdab = true;
		}
		setButtonUpdating();
	} else if ( 'done' in data ) {
		S.updating_db = false;
		S.updatingdab = false;
		setButtonUpdating();
		V.libraryhtml = V.librarylisthtml = V.playlisthtml ='';
		banner( 'refresh-library', 'Library Update', 'Done' );
	}
}
function psNotify( data ) {
	var icon    = data.icon;
	var title   = data.title;
	var message = data.message;
	var delay   = data.delay;
	
	banner( icon, title, message, delay );
	if ( message === 'Change track ...' ) { // audiocd
		clearIntervalAll();
	} else if ( title === 'Latest' ) {
		C.latest = 0;
		$( '#mode-latest gr' ).empty();
		if ( V.mode === 'latest' ) $( '#button-library' ).trigger( 'click' );
	} else if ( [ 'Off ...', 'Reboot ...' ].includes( message ) ) {
		pushstreamPower( message );
	}
}
function psOption( data ) {
	if ( V.local ) return
	
	if ( 'addons' in data ) {
		setButtonUpdateAddons();
		return
	}
	
	if ( 'snapclient' in data ) {
		S.snapclient = data.snapclient;
		var prefix = $time.is( ':visible' ) ? 'ti' : 'i';
		$( '#'+ prefix +'-snapclient' ).toggleClass( 'hide', ! S.snapclient );
		return
	}
	
	var option = Object.keys( data )[ 0 ];
	S[ option ] = Object.values( data )[ 0 ];
	setButtonOptions();
}
function psOrder( data ) {
	if ( V.local ) return
	
	O = data;
	orderLibrary();
}
function psPlaylist( data ) {
	if ( ! data.add
		&& ( V.local || V.sortable || $( '.pl-remove' ).length )
	) return
	
	clearTimeout( V.debounce );
	V.debounce = setTimeout( () => {
		if ( data == -1 ) {
			setPlaybackBlank();
			renderPlaylist( -1 );
			bannerHide();
		} else if ( 'autoplaycd' in data ) {
			V.autoplaycd = true;
			setTimeout( () => delete V.autoplaycd, 5000 );
		} else if ( 'html' in data ) {
			S.song = data.song;
			if ( V.playlist && ! V.savedpl && ! V.savedpltrack ) renderPlaylist( data );
		} else {
			var name = $( '#pl-path .lipath' ).text();
			if ( V.savedpltrack && data.playlist === name ) renderSavedPlTrack( name );
		}
		playbackStatusGet();
	}, 300 );
}
function psRadioList( data ) {
	if ( 'count' in data ) {
		C[ data.type ] = data.count;
		$( '#mode-'+ data.type +' gr' ).text( data.count );
	}
	if ( V.library ) {
		if ( V.librarylist && V.mode === data.type ) radioRefresh();
	} else if ( V.playlist ) {
		if ( V.savedpl ) {
			$( '#button-pl-playlists' ).trigger( 'click' );
		} else if ( V.savedpltrack ) {
			renderSavedPlTrack( $( '#savedpl-path .lipath' ).text() );
		} else {
			playlistGet();
		}
	}
	S.updatingdab = false;
	$( '#mi-dabupdate' ).addClass( 'hide' );
}
function psRelays( response ) {
	if ( 'done' in response || ! ( 'state' in response ) ) {
		$( '#infoX' ).trigger( 'click' );
		return
	}
	
	clearInterval( V.interval.relays );
	var state = response.state;
	var stopwatch = '<div class="msg-l"><object type="image/svg+xml" data="/assets/img/stopwatch.svg"></object></div>';
	if ( state === 'IDLE' ) {
		info( {
			  icon        : 'relays'
			, title       : 'Relays Countdown'
			, message     : stopwatch
						   +'<div class="msg-r wh">60</div>'
			, buttonlabel : ico( 'relays' ) +'Off'
			, buttoncolor : red
			, button      : () => bash( [ 'relays' ] )
			, oklabel     : ico( 'set0' ) +'Reset'
			, ok          : () => {
				bash( [ 'relaystimerreset' ] );
				banner( 'relays', 'GPIO Relays', 'Reset idle timer to '+ response.timer +'m' );
			}
		} );
		var delay     = 59;
		V.interval.relays = setInterval( () => {
			if ( delay ) {
				$( '.infomessage .wh' ).text( delay-- );
			} else {
				clearInterval( V.interval.relays );
				$( '#relays' ).removeClass( 'on' );
				$( '#mi-relays, #ti-relays' ).addClass( 'hide' );
			}
		}, 1000 );
	} else {
		if ( I.active ) {
			$( '#infoContent .msg-r' ).html( response.message );
			return
		}
		
		info( {
			  icon       : 'relays'
			, title      : 'Relays '+ state
			, message    : stopwatch
						  +'<div class="msg-r">'+ response.message +'</div>'
			, okno       : true
			, oknoreset  : true
			, beforeshow : () => {
				$( '#infoX' ).addClass( 'hide' );
				if ( state === 'OFF' ) $( '#infoContent .msg-r' ).addClass( 'wh' );
			}
		} );
	}
}
function psRestore( data ) {
	if ( data.restore === 'done' ) {
		banner( 'restore', 'Restore Settings', 'Done' );
		setTimeout( () => location.href = '/', 2000 );
	} else {
		loader();
		banner( 'restore blink', 'Restore Settings', 'Restart '+ data.restore +' ...', -1 );
	}
}
function psSavedPlaylists( data ) {
	var count   = data.count;
	C.playlists = count;
	if ( V.savedpl ) {
		count ? renderSavedPl( data ) : $( '#playlist' ).trigger( 'click' );
	} else if ( V.savedpltrack ) {
		if ( 'delete' in data && $( '#pl-path .lipath' ).text() === data.delete ) $( '#playlist' ).trigger( 'click' );
	}
	$( '#button-pl-playlists' ).toggleClass( 'disabled', count === 0 );
	$( '#mode-playlists gr' ).text( count || '' );
}
function psVolume( data ) {
	if ( data.type === 'mute' ) {
		$( '#volume-knob, #button-volume i' ).addClass( 'disabled' );
		S.volumemute = data.val;
		setVolume( 0 );
	} else if ( 'volumenone' in data ) {
		D.volumenone = data.volumenone;
		$volume.toggleClass( 'hide', ! D.volume || D.volumenone );
	} else {
		if ( ! data.type === 'updn' ) $( '#volume-knob, #button-volume i' ).addClass( 'disabled' );
		S.volumemute = 0;
		setVolume( data.val );
	}
}
function psVUmeter( data ) {
	$( '#vuneedle' ).css( 'transform', 'rotate( '+ data.val +'deg )' ); // 0-100 : 0-42 degree
}

