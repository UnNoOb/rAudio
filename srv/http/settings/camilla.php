<?php
$id_data = [
	'configuration' => [ 'name' => 'Configuration', 'setting' => 'custom' ]
];
$options = [
	  'Rate Adjust'         => 'enable_rate_adjust'
	, 'Resampling'          => 'enable_resampling'
	, 'Stop on Rate Change' => 'stop_on_rate_change'
];
$htmloptions = '';
foreach( $options as $label => $id ) {
	$input       = '<input id="'.$id.'" type="checkbox" class="switch custom">'
				  .'<div class="switchlabel"></div>';
	if ( $id !== 'stop_on_rate_change' ) $input.= '<i id="setting-'.$id.'" class="i-gear setting"></i>';
	$htmloptions.= '<div id="div'.$id.'">'
				  .'<div class="col-l single name">'.$label.'</div><div class="col-r">'.$input
				  .'</div><div style="clear:both"></div>'
				  .'</div>';
}
$htmldevices = '';
foreach( [ 'Sampling', 'Options', 'Capture', 'Playback' ] as $title ) {
	$id      = lcFirst( str_replace( ' ', '', $title ) );
	$html    = '<div class="statuslist"></div>';
	$setting = $title === 'Capture' || $title === 'Playback';
	$head    = '';
	if ( $title === 'Options' ) {
		$html .= $htmloptions;
	} else if ( $setting ) {
		$head  = '<heading class="subhead"><span class="headtitle">'.$title.i( 'gear', $id ).'</span></heading>';
	}
	$htmldevices.= '
<div id="div'.$id.'" class="section">
'.$head.'
<div class="content">'.$html.'</div>
</div>
';
}
$htmltabs = '<div id="divtabs">';
foreach( [ 'devices', 'filters', 'mixers', 'pipeline' ] as $id ) {
	$htmltabs.= '<div id="div'.$id.'" class="tab">';
	if ( $id === 'devices' ) {
		$htmltabs.= $htmldevices;
	} else if ( $id === 'pipeline' ) {
		$htmltabs.= '<svg class="flowchart hide" xmlns="http://www.w3.org/2000/svg" viewBox="20 0 500 300"></svg>';
	}
	$htmltabs.= '
<ul class="entries main"></ul>
<ul class="entries sub hide"></ul>
</div>
';
}

$htmltabs.= '</div>';

//////////////////////////////////
$head = [ 
	  'title'  => 'Status'
	, 'status' => 'camilladsp'
	, 'button' => [ 'refresh' => 'gear' ]
	, 'nohelp' => true
];
$body = [
	[
		  'id'    => 'configuration'
		, 'input' => '<select id="configuration"></select>'
	]
];
htmlSection( $head, $body, 'profile' );
//////////////////////////////////
$labels = 'State
	<br>Sample rate
	<br>Rate adjust
	<br>Clipped samples
	<br>Buffer level';
$body = [ htmlSectionStatus( 'status', $labels ) ];
htmlSection( '', $body, 'status' );
//////////////////////////////////
$head = [ 
	  'title'  => 'Devices'
	, 'nohelp' => true
];
$body = [ $htmltabs ];
htmlSection( $head, $body, 'settings' );
