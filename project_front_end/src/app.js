'use strict';
const http = require('http');
var assert = require('assert');
const express= require('express');
const app = express();
const mustache = require('mustache');
const filesystem = require('fs');
const url = require('url');
const port = Number(process.argv[2]);

const hbase = require('hbase')
var hclient = hbase({ host: process.argv[3], port: Number(process.argv[4])})

// function counterToNumber(c) {
// 	return Number(Buffer.from(c).readBigInt64BE());
// }

function rowToMap(row) {
	var stats = {}
	row.forEach(function (item) {
		stats[item['column']] = Number(item['$'])
	});
	return stats;
}

app.use(express.static('public'));
app.get('/service-requests.html', function (req, res) {
	hclient.table('cloftus_neighbourhoods').scan({ maxVersions: 1}, (err,rows) => {
		var template = filesystem.readFileSync("service-requests.mustache").toString();
		var html = mustache.render(template, {
			neighbourhoods : rows
		});
		res.send(html)
	})
});

function removePrefix(text, prefix) {
	return text.substr(prefix.length)
}

app.get('/chicago-service-requests.html',function (req, res) {
	const neighbourhood=req.query['neighbourhood'];

	hclient.table('cloftus_neighbourhoods').row(neighbourhood).get(function (err, cells) {
		const commareaInfo = rowToMap(cells);
		const commarea = (commareaInfo['nbhd:commarea']).toString().padStart(2, '0');

		function processYearRecord(yearRecord) {
			var result = { year : yearRecord['year']};
			console.log(yearRecord);
			["street_lights", "rodents", "graffiti", "potholes", "sanitation_codes"].forEach(request_type => {
				var request_num = yearRecord[request_type]
				result[request_type] = request_num == 0 ? "-" : request_num;
			})
			return result;
		}

		function requestInfo(cells) {
			var result = [];
			var yearRecord;
			cells.forEach(function(cell) {
				var year = Number(cell['key'].substr(commarea.length + 1))
				if(yearRecord === undefined)  {
					yearRecord = { year: year }
				} else if (yearRecord['year'] != year ) {
					result.push(processYearRecord(yearRecord))
					yearRecord = { year: year }
				}
				yearRecord[removePrefix(cell['column'],'request:')] = Number(cell['$'])
			})
			result.push(processYearRecord(yearRecord))
			console.info(result)
			return result;
		}

		hclient.table('cloftus_service_requests_nbhds').scan({
				filter: {type : "PrefixFilter",
					value: commarea},
				maxVersions: 1},
			(err, cells) => {
				var ri = requestInfo(cells);
				var template = filesystem.readFileSync("requests-result.mustache").toString();
				var html = mustache.render(template, {
					requestInfo : ri,
					neighbourhood : neighbourhood
				});
				res.send(html)
			})
	})
});

/* Send simulated weather to kafka */

var kafka = require('kafka-node');
var Producer = kafka.Producer;
var KeyedMessage = kafka.KeyedMessage;
var kafkaClient = new kafka.KafkaClient({kafkaHost: process.argv[5]});
var kafkaProducer = new Producer(kafkaClient);

app.get('/requests.html',function (req, res) {
	var neighbourhood_val = req.query['neighbourhood'];
	var street_lights_val = (req.query['street_lights']) ? true : false;
	var rodents_val = (req.query['rodents']) ? true : false;
	var graffiti_val = (req.query['graffiti']) ? true : false;
	var potholes_val = (req.query['potholes']) ? true : false;
	var sanitation_codes_val = (req.query['sanitation_codes']) ? true : false;
	var report = {
		neighbourhood : neighbourhood_val,
		street_lights : street_lights_val,
		rodents : rodents_val,
		graffiti : graffiti_val,
		potholes : potholes_val,
		sanitation_codes : sanitation_codes_val,
	};

	kafkaProducer.send([{ topic: 'cloftus-service-reports', messages: JSON.stringify(report)}],
		function (err, data) {
			console.log("Kafka Error: " + err)
			console.log(data);
			console.log(report);
			res.redirect('submit-service-request.html');
		});
});

app.listen(port);
