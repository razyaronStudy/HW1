from flask import Flask, request, jsonify
from datetime import datetime

app = Flask(__name__)

parking_lot_data = {}  # Data structure to store parking lot information


@app.route('/entry', methods=['POST'])
def entry():
    plate = request.args.get('plate')
    parking_lot = request.args.get('parkingLot')

    # Generate a unique ticket ID
    ticket_id = generate_ticket_id()

    # Record the entry information
    entry_time = datetime.now()
    parking_lot_data[ticket_id] = {
        'plate': plate,
        'entry_time': entry_time,
        'parking_lot': parking_lot
    }

    return jsonify({'ticketId': ticket_id}), 200


@app.route('/exit', methods=['POST'])
def exit():
    ticket_id = request.args.get('ticketId')

    if ticket_id in parking_lot_data:
        # Calculate parked time and charge
        exit_time = datetime.now()
        entry_time = parking_lot_data[ticket_id]['entry_time']
        parked_time = exit_time - entry_time
        charge = calculate_charge(parked_time)

        # Retrieve the parking lot and plate information
        plate = parking_lot_data[ticket_id]['plate']
        parking_lot = parking_lot_data[ticket_id]['parking_lot']

        # Remove the ticket from the data structure
        del parking_lot_data[ticket_id]

        # Return the exit information and charge
        return jsonify({
            'plate': plate,
            'parked_time': str(parked_time),
            'parking_lot': parking_lot,
            'charge': charge
        }), 200
    else:
        return jsonify({'error': 'Invalid ticket ID'}), 400


def generate_ticket_id():
    # Generate a unique ticket ID based on timestamp or using a more sophisticated method
    return str(datetime.now().timestamp())


def calculate_charge(parked_time):
    # Calculate the charge based on parked time (rounded up to the nearest 15 minutes increment)
    hours = parked_time.total_seconds() // 3600
    minutes = (parked_time.total_seconds() % 3600) // 60
    quarter_hours = (minutes + 14) // 15  # Rounded up to the nearest 15 minutes
    charge = (hours + quarter_hours / 4) * 10  # Charge per hour is $10

    return charge


if __name__ == '__main__':
    app.run(debug=True)
